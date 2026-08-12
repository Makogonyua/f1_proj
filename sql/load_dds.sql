
TRUNCATE TABLE dds.r_circuit;
INSERT INTO dds.r_circuit (circuit_key, circuit_name, country_code)
SELECT DISTINCT
    circuit_key,
    circuit_short_name,
    country_code
FROM ods.dim_meeting
WHERE circuit_key IS NOT NULL;


TRUNCATE TABLE dds.r_meeting;
INSERT INTO dds.r_meeting (meeting_key, meeting_name, circuit_key, date_start)
SELECT DISTINCT
    meeting_key,
    meeting_name,
    circuit_key,
    date_start
FROM ods.dim_meeting;


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


TRUNCATE TABLE dds.r_driver_season;
INSERT INTO dds.r_driver_season (season, driver_number, name_acronym, team_name)
SELECT DISTINCT ON (m."year", d.driver_number)
    m."year" AS season,
    d.driver_number,
    d.name_acronym,
    d.team_name
FROM ods.dim_driver d
JOIN ods.dim_meeting m ON d.meeting_key = m.meeting_key
WHERE d.meeting_key IS NOT NULL
  AND m."year" IS NOT NULL
ORDER BY m."year", d.driver_number, d.meeting_key DESC; 


TRUNCATE TABLE dds.r_driver_season;
INSERT INTO dds.r_driver_season (season, driver_number, name_acronym, team_name)
SELECT DISTINCT ON (m."year", d.driver_number)
    m."year" AS season,
    d.driver_number,
    d.name_acronym,
    d.team_name
FROM ods.dim_driver d
JOIN ods.dim_meeting m ON d.meeting_key = m.meeting_key
WHERE d.meeting_key IS NOT NULL
  AND m."year" IS NOT NULL
ORDER BY m."year", d.driver_number, d.meeting_key DESC; 

TRUNCATE TABLE dds.overtakes;
INSERT INTO dds.overtakes (
    session_key, 
    meeting_key, 
    overtaking_driver_number, 
    overtaken_driver_number, 
    "position", 
    ts
)
SELECT
    session_key,
    meeting_key,
    overtaking_driver_number,
    overtaken_driver_number::int4,
    "position"::int4,
    "date" AS ts
FROM ods.fct_overtakes;

TRUNCATE TABLE dds."position";
INSERT INTO dds."position" (session_key, driver_number, ts, "position")
SELECT
    session_key,
    driver_number,
    "date" AS ts,
    "position"
FROM ods.fct_position
ON CONFLICT (session_key, driver_number, ts) DO NOTHING;  -- Защита от дублей

TRUNCATE TABLE dds.weather;
INSERT INTO dds.weather (
    session_key, meeting_key, ts, 
    air_temperature, track_temperature, humidity, pressure,
    wind_speed, rainfall
)
SELECT
    session_key,
    meeting_key, 
    "date" AS ts,
    air_temperature::numeric,
    track_temperature::numeric,
    humidity::numeric,
    pressure::numeric,
    wind_speed::numeric,
    (COALESCE(rainfall, 0) > 0) AS rainfall
FROM ods.fct_weather;

TRUNCATE TABLE dds.race_control;
INSERT INTO dds.race_control (
    session_key, ts, category, flag, message, 
    driver_number, lap_number
)
SELECT DISTINCT
    COALESCE(NULLIF(session_key, 'NaN'::numeric)::int4, 0),
    "date" AS ts,
    category,
    flag,
    message,
    COALESCE(NULLIF(driver_number, 'NaN'::numeric)::int4, 0),
    COALESCE(NULLIF(lap_number, 'NaN'::numeric)::int4, 0)
FROM ods.fct_race_control
ON CONFLICT (session_key, ts, message) DO NOTHING;

TRUNCATE TABLE dds.championship_drivers;
INSERT INTO dds.championship_drivers (
    session_key, driver_number,
    position_current, position_start,
    points_current, points_start
)
SELECT
    session_key::int4,
    driver_number::int4,
    COALESCE(NULLIF(position_current, 'NaN'::numeric)::int4, 0),
    COALESCE(NULLIF(position_start, 'NaN'::numeric)::int4, 0),
    COALESCE(NULLIF(points_current, 'NaN'::numeric)::int4, 0),
    COALESCE(NULLIF(points_start, 'NaN'::numeric)::int4, 0)
FROM ods.fct_championship_drivers;

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
INSERT INTO dds.pit (session_key, driver_number, lap_number, pit_duration)
SELECT
    session_key,
    driver_number,
    lap_number,
    pit_duration::numeric
FROM ods.fct_pit;