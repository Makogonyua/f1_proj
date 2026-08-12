TRUNCATE TABLE dm.pit_season;

INSERT INTO dm.pit_season (season, circuit_name, team_name, stop_duration
)

select season, circuit_name, team_name, stop_duration
from( 
select distinct
pt.session_key,
pt.driver_number,
pt.lap_number,
pt.stop_duration,
d.team_name,
c.circuit_name, 
ds.season, row_number() over(partition by c.circuit_name, ds.season order by pt.stop_duration ) as cnt
from dds.pit pt
JOIN dds.r_session s ON pt.session_key = s.session_key
JOIN dds.r_meeting m ON s.meeting_key = m.meeting_key
JOIN dds.r_circuit c ON m.circuit_key = c.circuit_key
JOIN dds.r_driver_season ds 
        ON pt.driver_number = ds.driver_number 
        AND EXTRACT(YEAR FROM m.date_start)::int = ds.season
JOIN dds.r_driver d ON ds.name_acronym = d.name_acronym
JOIN ods.dim_driver od ON d.name_acronym = od.name_acronym
WHERE s.session_type = 'Race'  AND s.session_name = 'Race' and pt.stop_duration != 'NaN' ) as rank_ where cnt = 1;


TRUNCATE TABLE dm.flag_season;
INSERT INTO dm.flag_season (season, circuit_name, yellow_flag, red_flag
)

select 
EXTRACT(YEAR FROM m.date_start)::int as season,
c.circuit_name,
count(flag) filter (where flag = 'YELLOW') as yellow_flag,
count(flag) filter (where flag = 'RED') as red_flag


from (select distinct session_key, left(ts::text,16), flag
from dds.race_control ) rc
JOIN dds.r_session s ON rc.session_key = s.session_key
JOIN dds.r_meeting m ON s.meeting_key = m.meeting_key
JOIN dds.r_circuit c ON m.circuit_key = c.circuit_key
where flag = 'YELLOW' or flag = 'RED'

group by EXTRACT(YEAR FROM m.date_start)::int, c.circuit_name;



TRUNCATE TABLE dds.session_result;
INSERT INTO dds.session_result (
    session_key, driver_number,
    "position", number_of_laps, duration, gap_to_leader,
    status_code, points
)
SELECT
    session_key::int4,
    driver_number::int4,
        COALESCE(NULLIF(position, 'NaN'::numeric)::int4, 0),
    COALESCE(NULLIF(number_of_laps, 'NaN'::numeric)::int4, 0),
    duration::numeric(17, 3),
    gap_to_leader::numeric(17, 3),
    CASE
        WHEN dsq = TRUE THEN 'DSQ'
        WHEN dns = TRUE THEN 'DNS'
        WHEN dnf IS NOT NULL AND dnf != '' THEN 'DNF'
        ELSE 'FIN'
    END AS status_code,
    COALESCE(NULLIF(points, 'NaN'::numeric)::int4, 0)
FROM ods.fct_session_result;

TRUNCATE TABLE dds.pit;
INSERT INTO dds.pit (session_key, driver_number, lap_number, pit_duration,stop_duration)
SELECT
    session_key,
    driver_number,
    lap_number,
    pit_duration::numeric,
    stop_duration::numeric
FROM ods.fct_pit;


TRUNCATE TABLE dm.constructor_podium;
INSERT INTO dm.constructor_podium (
    season, position, team_name,
    total_points, wins, podiums
)
WITH team_season_stats AS (
    SELECT 
        season,
        team_name,
        SUM(points_current) AS total_points
    FROM dm.championship_standings
    WHERE meeting_order = (
        SELECT MAX(meeting_order) 
        FROM dm.championship_standings cs2 
        WHERE cs2.season = championship_standings.season
    )
    GROUP BY season, team_name
),
ranked AS (
    SELECT 
        season,
        team_name,
        total_points,
        ROW_NUMBER() OVER (PARTITION BY season ORDER BY total_points DESC) AS position
    FROM team_season_stats
)
SELECT 
    ranked.season,
    ranked.position,
    ranked.team_name,
    ranked.total_points,
    COALESCE(stats.wins, 0) AS wins,
    COALESCE(stats.podiums, 0) AS podiums
FROM ranked
LEFT JOIN (
    SELECT 
        EXTRACT(YEAR FROM m.date_start)::int AS season,
        d.team_name,
        SUM(CASE WHEN sr."position" = 1 THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN sr."position" <= 3 THEN 1 ELSE 0 END) AS podiums
    FROM dds.session_result sr
    JOIN dds.r_session s ON sr.session_key = s.session_key
    JOIN dds.r_meeting m ON s.meeting_key = m.meeting_key
    JOIN dds.r_driver_season ds 
        ON sr.driver_number = ds.driver_number 
        AND EXTRACT(YEAR FROM m.date_start)::int = ds.season
    JOIN dds.r_driver d ON ds.name_acronym = d.name_acronym
    WHERE s.session_type = 'Race'
    GROUP BY EXTRACT(YEAR FROM m.date_start)::int, d.team_name
) stats 
    ON ranked.team_name = stats.team_name
    AND ranked.season = stats.season
WHERE ranked.position <= 3
ORDER BY ranked.season, ranked.position;

TRUNCATE TABLE dm.driver_race_stats;
INSERT INTO dm.driver_race_stats (
    driver_number, name_acronym, driver_name, team_name, season, meeting_name,
    finish_position, start_position, number_of_laps, duration, gap_to_leader,
    status_code, points, is_win, is_podium, is_dnf
)
SELECT 
    sr.driver_number,
    d.name_acronym,
    d.full_name AS driver_name,
    d.team_name,
    EXTRACT(YEAR FROM m.date_start)::int AS season,
    m.meeting_name,
    sr."position" AS finish_position,
    quali_sr."position" AS start_position,
    sr.number_of_laps,
    case when sr.duration = 'NaN' then 0 else sr.duration end as duration,
    case when sr.gap_to_leader = 'NaN' then 0 else sr.gap_to_leader end as gap_to_leader,
    sr.status_code,
    sr.points,
    CASE WHEN sr."position" = 1 THEN 1 ELSE 0 END AS is_win,
    CASE WHEN sr."position" <= 3 THEN 1 ELSE 0 END AS is_podium,
    CASE WHEN sr.status_code = 'DNF' THEN 1 ELSE 0 END AS is_dnf
FROM dds.session_result sr
JOIN dds.r_session s ON sr.session_key = s.session_key
JOIN dds.r_meeting m ON s.meeting_key = m.meeting_key
JOIN dds.r_driver_season ds 
    ON sr.driver_number = ds.driver_number 
    AND EXTRACT(YEAR FROM m.date_start)::int = ds.season
JOIN dds.r_driver d ON ds.name_acronym = d.name_acronym
LEFT JOIN (
    SELECT 
        quali_m.meeting_key,
        quali_sr.driver_number,
        quali_sr."position"
    FROM dds.session_result quali_sr
    JOIN dds.r_session quali_s ON quali_sr.session_key = quali_s.session_key
    JOIN dds.r_meeting quali_m ON quali_s.meeting_key = quali_m.meeting_key
    WHERE quali_s.session_type = 'Qualifying'
) quali_sr 
    ON quali_sr.meeting_key = m.meeting_key 
    AND quali_sr.driver_number = sr.driver_number
WHERE s.session_type = 'Race';

TRUNCATE TABLE dm.constructor_standings;
INSERT INTO dm.constructor_standings (
    season, date_start, meeting_name, team_name, total_points, wins, podiums, drivers_count
)
SELECT 
    EXTRACT(YEAR FROM m.date_start)::int AS season,
    m.date_start as date_start,
    m.meeting_name,
    d.team_name,
    SUM(sr.points) OVER (ORDER BY m.date_start,d.team_name) AS total_points,
    SUM(CASE WHEN sr."position" = 1 THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN sr."position" <= 3 THEN 1 ELSE 0 END) AS podiums,
    COUNT(DISTINCT sr.driver_number) AS drivers_count
FROM dds.session_result sr
JOIN dds.r_session s ON sr.session_key = s.session_key
JOIN dds.r_meeting m ON s.meeting_key = m.meeting_key
JOIN dds.r_driver_season ds 
    ON sr.driver_number = ds.driver_number 
    AND EXTRACT(YEAR FROM m.date_start)::int = ds.season
JOIN dds.r_driver d ON ds.name_acronym = d.name_acronym
WHERE s.session_type = 'Race'
GROUP BY EXTRACT(YEAR FROM m.date_start)::int,  m.date_start, m.meeting_name, d.team_name, sr.points;


TRUNCATE TABLE dm.driver_lap_stats;
INSERT INTO dm.driver_lap_stats (
    driver_number, name_acronym, driver_name, team_name, season, meeting_name,
    session_type, total_laps, avg_lap_time, best_lap_time,
    avg_sector_1, avg_sector_2, avg_sector_3
)
SELECT 
    l.driver_number,
    d.name_acronym,
    d.full_name AS driver_name,
    d.team_name,
    EXTRACT(YEAR FROM m.date_start)::int AS season,
    m.meeting_name,
    s.session_type,
    COUNT(*) AS total_laps,
    AVG(l.lap_duration) AS avg_lap_time,
    MIN(l.lap_duration) AS best_lap_time,
    AVG(l.duration_sector_1) AS avg_sector_1,
    AVG(l.duration_sector_2) AS avg_sector_2,
    AVG(l.duration_sector_3) AS avg_sector_3
FROM dds.laps l
JOIN dds.r_session s ON l.session_key = s.session_key
JOIN dds.r_meeting m ON s.meeting_key = m.meeting_key
JOIN dds.r_driver_season ds 
    ON l.driver_number = ds.driver_number 
    AND EXTRACT(YEAR FROM m.date_start)::int = ds.season
JOIN dds.r_driver d ON ds.name_acronym = d.name_acronym
WHERE l.lap_duration IS NOT NULL
GROUP BY l.driver_number, d.name_acronym, d.full_name, d.team_name, 
         EXTRACT(YEAR FROM m.date_start)::int, m.meeting_name, s.session_type;

TRUNCATE TABLE dm.driver_profile;
INSERT INTO dm.driver_profile (
    driver_number, name_acronym, full_name, country_code, team_name, season, total_sessions
)
SELECT 
    ds.driver_number,
    d.name_acronym,
    d.full_name,
    d.country_code,
    d.team_name,
    ds.season,
    COUNT(DISTINCT s.session_key) AS total_sessions
FROM dds.r_driver d
JOIN dds.r_driver_season ds ON d.name_acronym = ds.name_acronym
LEFT JOIN dds.r_session s 
    ON ds.season = EXTRACT(YEAR FROM s.date_start)
GROUP BY ds.driver_number, d.name_acronym, d.full_name, d.country_code, 
         d.team_name, ds.season;

TRUNCATE TABLE dm.championship_standings;
INSERT INTO dm.championship_standings (
    season, meeting_key, meeting_name, meeting_date, meeting_order,
    circuit_key, circuit_name, country_code,
    session_key, session_type, driver_number, name_acronym, driver_name, driver_country, driver_headshot_url,
    team_name, position_current, position_start, points_current, points_start, points_earned
)
SELECT distinct
    base.season,
    base.meeting_key,
    base.meeting_name,
    base.meeting_date,
    base.meeting_order,
    base.circuit_key,
    base.circuit_name,
    base.country_code,
    base.session_key,
    base.session_type,
    base.driver_number,
    base.name_acronym,
    base.driver_name,
    base.driver_country,
    '' as driver_headshot_url,
    base.team_name,
    base.position_current,
    base.position_start,
    base.points_current,
    base.points_start,
    base.points_current - base.points_start AS points_earned
FROM (
    SELECT 
        EXTRACT(YEAR FROM m.date_start)::int AS season,
        m.meeting_key,
        m.meeting_name,
        m.date_start AS meeting_date,
        DENSE_RANK() OVER (
            PARTITION BY EXTRACT(YEAR FROM m.date_start) 
            ORDER BY m.date_start
        ) AS meeting_order,
        m.circuit_key,
        c.circuit_name,
        c.country_code,
        s.session_key,
        s.session_type,
        cd.driver_number,
        d.name_acronym,
        d.full_name AS driver_name,
        d.country_code AS driver_country,
        od.headshot_url AS driver_headshot_url,
        ds.team_name, 
        cd.position_current,
        cd.position_start,
        cd.points_current,
        cd.points_start
    FROM dds.championship_drivers cd
    JOIN dds.r_session s ON cd.session_key = s.session_key
    JOIN dds.r_meeting m ON s.meeting_key = m.meeting_key
    JOIN dds.r_circuit c ON m.circuit_key = c.circuit_key
    JOIN dds.r_driver_season ds 
        ON cd.driver_number = ds.driver_number 
        AND EXTRACT(YEAR FROM m.date_start)::int = ds.season
    JOIN dds.r_driver d ON ds.name_acronym = d.name_acronym
    JOIN ods.dim_driver od ON d.name_acronym = od.name_acronym
    WHERE s.session_type = 'Race'
      AND s.session_name = 'Race'
) base;


TRUNCATE TABLE dds.r_session;
INSERT INTO dds.r_session (
    session_key, meeting_key, date_start, date_end, 
    is_cancelled, session_type, session_name 
)
SELECT DISTINCT
    session_key,
    meeting_key,
    date_start,
    date_end,
    COALESCE(is_cancelled, FALSE),
    session_type,
    session_name 
FROM ods.dim_session;


TRUNCATE TABLE dm.constructor_podium;
INSERT INTO dm.constructor_podium (
    season, position, team_name,
    total_points, wins, podiums
)
WITH team_season_stats AS (

    SELECT 
        season,
        team_name,
        SUM(points_current) AS total_points
    FROM dm.championship_standings
    WHERE meeting_order = (
        SELECT MAX(meeting_order) 
        FROM dm.championship_standings cs2 
        WHERE cs2.season = championship_standings.season
    )
    GROUP BY season, team_name
),
ranked AS (
    SELECT 
        season,
        team_name,
        total_points,
        ROW_NUMBER() OVER (PARTITION BY season ORDER BY total_points DESC) AS position
    FROM team_season_stats
)
SELECT 
    ranked.season,
    ranked.position,
    ranked.team_name,
    ranked.total_points,
    COALESCE(stats.wins, 0) AS wins,
    COALESCE(stats.podiums, 0) AS podiums
FROM ranked
LEFT JOIN (
    SELECT 
        EXTRACT(YEAR FROM m.date_start)::int AS season,
        d.team_name,
        SUM(CASE WHEN sr."position" = 1 THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN sr."position" <= 3 THEN 1 ELSE 0 END) AS podiums
    FROM dds.session_result sr
    JOIN dds.r_session s ON sr.session_key = s.session_key
    JOIN dds.r_meeting m ON s.meeting_key = m.meeting_key
    JOIN dds.r_driver_season ds 
        ON sr.driver_number = ds.driver_number 
        AND EXTRACT(YEAR FROM m.date_start)::int = ds.season
    JOIN dds.r_driver d ON ds.name_acronym = d.name_acronym
    WHERE s.session_type = 'Race'
    GROUP BY EXTRACT(YEAR FROM m.date_start)::int, d.team_name
) stats 
    ON ranked.team_name = stats.team_name
    AND ranked.season = stats.season
WHERE ranked.position <= 3
ORDER BY ranked.season, ranked.position;

TRUNCATE TABLE dds.r_driver_season;
INSERT INTO dds.r_driver_season (season, driver_number, name_acronym, team_name)
SELECT DISTINCT ON (season, driver_number) 
    season,
    driver_number,
    name_acronym,
    team_name
FROM (
    SELECT DISTINCT
        m."year" AS season,
        ds.driver_number,
        d.name_acronym,
        d.team_name
    FROM (
        SELECT DISTINCT driver_number::int4, session_key::int4 FROM ods.fct_laps
        UNION
        SELECT DISTINCT driver_number::int4, session_key::int4 FROM ods.fct_session_result
        UNION
        SELECT DISTINCT driver_number::int4, session_key::int4 FROM ods.fct_championship_drivers
    ) ds
    JOIN ods.dim_session s ON ds.session_key = s.session_key
    JOIN ods.dim_meeting m ON s.meeting_key = m.meeting_key
    JOIN ods.dim_driver d ON ds.driver_number = d.driver_number
    WHERE d.name_acronym IS NOT NULL
      AND m."year" IS NOT NULL
      AND d.team_name IS NOT NULL
) sub
ORDER BY season, driver_number, team_name;

TRUNCATE TABLE dm.constructor_stats;
INSERT INTO dm.constructor_stats (
    team_name, season, avg_finish_position, avg_start_position,
    total_dnf, total_entries, dnf_percentage
)
SELECT 
    d.team_name,
    EXTRACT(YEAR FROM m.date_start)::int AS season,
    AVG(sr."position") AS avg_finish_position,
    AVG(quali_sr."position") AS avg_start_position, 
    SUM(CASE WHEN sr.status_code = 'DNF' THEN 1 ELSE 0 END) AS total_dnf,
    COUNT(*) AS total_entries,
    ROUND(SUM(CASE WHEN sr.status_code = 'DNF' THEN 1 ELSE 0 END)::numeric / COUNT(*) * 100, 2) AS dnf_percentage
FROM dds.session_result sr
JOIN dds.r_session s ON sr.session_key = s.session_key
JOIN dds.r_meeting m ON s.meeting_key = m.meeting_key
JOIN dds.r_driver_season ds 
    ON sr.driver_number = ds.driver_number 
    AND EXTRACT(YEAR FROM m.date_start)::int = ds.season
JOIN dds.r_driver d ON ds.name_acronym = d.name_acronym
LEFT JOIN (
    SELECT 
        quali_m.meeting_key,
        quali_sr.driver_number,
        quali_sr."position"
    FROM dds.session_result quali_sr
    JOIN dds.r_session quali_s ON quali_sr.session_key = quali_s.session_key
    JOIN dds.r_meeting quali_m ON quali_s.meeting_key = quali_m.meeting_key
    WHERE quali_s.session_type = 'Qualifying'
) quali_sr 
    ON quali_sr.meeting_key = m.meeting_key 
    AND quali_sr.driver_number = sr.driver_number
WHERE s.session_type = 'Race'
GROUP BY d.team_name, EXTRACT(YEAR FROM m.date_start)::int;

TRUNCATE TABLE dm.constructor_teammate_gap;
INSERT INTO dm.constructor_teammate_gap (
    team_name, season, meeting_name, driver_1, driver_2,
    pos_driver_1, pos_driver_2, position_gap, winner
)
SELECT 
    ds1.team_name,  
    EXTRACT(YEAR FROM m.date_start)::int AS season,
    m.meeting_name,
    ds1.name_acronym AS driver_1,
    ds2.name_acronym AS driver_2,
    sr1."position" AS pos_driver_1,
    sr2."position" AS pos_driver_2,
    ABS(sr1."position" - sr2."position") AS position_gap,
    CASE 
        WHEN sr1."position" < sr2."position" THEN ds1.name_acronym
        ELSE ds2.name_acronym
    END AS winner
FROM dds.session_result sr1
JOIN dds.session_result sr2 
    ON sr1.session_key = sr2.session_key 
    AND sr1.driver_number < sr2.driver_number
JOIN dds.r_session s ON sr1.session_key = s.session_key
JOIN dds.r_meeting m ON s.meeting_key = m.meeting_key
JOIN dds.r_driver_season ds1 
    ON sr1.driver_number = ds1.driver_number 
    AND EXTRACT(YEAR FROM m.date_start)::int = ds1.season
JOIN dds.r_driver_season ds2 
    ON sr2.driver_number = ds2.driver_number 
    AND EXTRACT(YEAR FROM m.date_start)::int = ds2.season
WHERE ds1.team_name = ds2.team_name  
  AND s.session_type = 'Race';