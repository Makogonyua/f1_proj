
CREATE TABLE IF NOT EXISTS dm.championship_standings_local
(
    season Int32,
    meeting_key Int32,
    meeting_name String,
    meeting_date Nullable(DateTime),
    meeting_order Int32,
    circuit_key Int32,
    circuit_name String,
    country_code String,
    session_key Int32,
    session_type String,
    driver_number Int32,
    name_acronym String,
    driver_name String,
    driver_country String,
    driver_headshot_url String,
    team_name String,
    position_current Int32,
    position_start Int32,
    points_current Int32,
    points_start Int32,
    points_earned Int32
)
ENGINE = MergeTree()
ORDER BY (season, meeting_order, driver_number);

CREATE TABLE IF NOT EXISTS dm.driver_profile_local
(
    driver_number Int32,
    name_acronym String,
    full_name String,
    country_code String,
    team_name String,
    season Int32,
    total_sessions Int64
)
ENGINE = MergeTree()
ORDER BY (season, driver_number);

CREATE TABLE IF NOT EXISTS dm.driver_race_stats_local
(
    driver_number Int32,
    name_acronym String,
    driver_name String,
    team_name String,
    season Int32,
    meeting_name String,
    finish_position Nullable(Int32),
    start_position Nullable(Int32),
    number_of_laps Nullable(Int32),
    duration Nullable(Float64),
    gap_to_leader Nullable(Float64),
    status_code String,
    points Nullable(Int32),
    is_win Int32,
    is_podium Int32,
    is_dnf Int32
)
ENGINE = MergeTree()
ORDER BY (season, meeting_name, driver_number);

CREATE TABLE IF NOT EXISTS dm.driver_lap_stats_local
(
    driver_number Int32,
    name_acronym String,
    driver_name String,
    team_name String,
    season Int32,
    meeting_name String,
    session_type String,
    total_laps Int64,
    avg_lap_time Float64,
    best_lap_time Float64,
    avg_sector_1 Float64,
    avg_sector_2 Float64,
    avg_sector_3 Float64
)
ENGINE = MergeTree()
ORDER BY (season, meeting_name, driver_number);

CREATE TABLE IF NOT EXISTS dm.constructor_standings_local
(
    season Int32,
    meeting_name String,
    team_name String,
    total_points Float64,
    wins Int64,
    podiums Int64,
    drivers_count Int64
)
ENGINE = MergeTree()
ORDER BY (season, meeting_name, team_name);

CREATE TABLE IF NOT EXISTS dm.constructor_stats_local
(
    team_name String,
    season Int32,
    avg_finish_position Float64,
    avg_start_position Float64,
    total_dnf Int64,
    total_entries Int64,
    dnf_percentage Float64
)
ENGINE = MergeTree()
ORDER BY (season, team_name);

CREATE TABLE IF NOT EXISTS dm.constructor_teammate_gap_local
(
    team_name String,
    season Int32,
    meeting_name String,
    driver_1 String,
    driver_2 String,
    pos_driver_1 Int32,
    pos_driver_2 Int32,
    position_gap Int32,
    winner String
)
ENGINE = MergeTree()
ORDER BY (season, meeting_name, team_name);

CREATE TABLE IF NOT EXISTS dm.circuit_map_local
(
    circuit_key Int32,
    circuit_name String,
    latitude Nullable(Float64),
    longitude Nullable(Float64),
    country_code String,
    timezone String,
    meeting_key Int32,
    meeting_name String,
    meeting_date Nullable(DateTime),
    season Int32,
    meeting_order Int32,
    is_cancelled UInt8,
    is_future UInt8,
    is_past UInt8,
    race_status String
)
ENGINE = MergeTree()
ORDER BY (season, meeting_order);

CREATE TABLE IF NOT EXISTS dm.podium_local
(
    season Int32,
    position Int32,
    medal String,
    driver_name String,
    name_acronym String,
    team_name String,
    points Int32,
    wins Int32,
    podiums Int32,
    driver_headshot_url String
)
ENGINE = MergeTree()
ORDER BY (season, position);

CREATE TABLE IF NOT EXISTS dm.constructor_podium_local
(
    season Int32,
    position Int32,
    medal String,
    team_name String,
    total_points Int32,
    wins Int32,
    podiums Int32,
    drivers_count Int32
)
ENGINE = MergeTree()
ORDER BY (season, position);


CREATE TABLE IF NOT EXISTS dm.pit_season_local
(

    season Int32,
    circuit_name String,
    team_name String,
    stop_duration Float64,

)
ENGINE = MergeTree()
ORDER BY (season, circuit_name);


CREATE TABLE IF NOT EXISTS dm.flag_season_local
(

    season Int32,
    circuit_name String,
    yellow_flag Int64,
    red_flag Int64
)
ENGINE = MergeTree()
ORDER BY (season, circuit_name);



TRUNCATE dm.championship_standings_local;
INSERT INTO dm.championship_standings_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'championship_standings', '*user*', '*pass*', 'dm');

TRUNCATE dm.driver_profile_local;
INSERT INTO dm.driver_profile_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'driver_profile', '*user*', '*pass*', 'dm');

TRUNCATE dm.driver_race_stats_local;
INSERT INTO dm.driver_race_stats_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'driver_race_stats', '*user*', '*pass*', 'dm');

TRUNCATE dm.driver_lap_stats_local;
INSERT INTO dm.driver_lap_stats_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'v_driver_lap_stats_for_ch', '*user*', '*pass*', 'dm');

TRUNCATE dm.constructor_podium_local;
INSERT INTO dm.constructor_podium_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'v_constructor_podium_for_ch', '*user*', '*pass*', 'dm');

TRUNCATE dm.constructor_standings_local;
INSERT INTO dm.constructor_standings_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'v_constructor_standings_for_ch', '*user*', '*pass*', 'dm');

TRUNCATE dm.constructor_stats_local;
INSERT INTO dm.constructor_stats_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'constructor_stats', '*user*', '*pass*', 'dm');

TRUNCATE dm.constructor_teammate_gap_local;
INSERT INTO dm.constructor_teammate_gap_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'constructor_teammate_gap', '*user*', '*pass*', 'dm');

TRUNCATE dm.circuit_map_local;
INSERT INTO dm.circuit_map_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'circuit_map', '*user*', '*pass*', 'dm');

TRUNCATE dm.podium_local;
INSERT INTO dm.podium_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'podium', '*user*', '*pass*', 'dm');

TRUNCATE dm.pit_season_local;
INSERT INTO dm.pit_season_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'pit_season', '*user*', '*pass*', 'dm');

TRUNCATE dm.flag_season_local;
INSERT INTO dm.flag_season_local
SELECT * FROM postgresql('localhost:5432', 'analytics', 'flag_season', '*user*', '*pass*', 'dm');


DROP VIEW IF EXISTS dm.championship_standings;
CREATE VIEW dm.championship_standings AS
SELECT * FROM dm.championship_standings_local;

DROP VIEW IF EXISTS dm.driver_profile;
CREATE VIEW dm.driver_profile AS
SELECT * FROM dm.driver_profile_local;

DROP VIEW IF EXISTS dm.driver_race_stats;
CREATE VIEW dm.driver_race_stats AS
SELECT * FROM dm.driver_race_stats_local;

DROP VIEW IF EXISTS dm.driver_lap_stats;
CREATE VIEW dm.driver_lap_stats AS
SELECT * FROM dm.driver_lap_stats_local;

DROP VIEW IF EXISTS dm.constructor_podium;
CREATE VIEW dm.constructor_podium AS
SELECT * FROM dm.constructor_podium_local;

DROP VIEW IF EXISTS dm.constructor_standings;
CREATE VIEW dm.constructor_standings AS
SELECT * FROM dm.constructor_standings_local;

DROP VIEW IF EXISTS dm.constructor_stats;
CREATE VIEW dm.constructor_stats AS
SELECT * FROM dm.constructor_stats_local;

DROP VIEW IF EXISTS dm.constructor_teammate_gap;
CREATE VIEW dm.constructor_teammate_gap AS
SELECT * FROM dm.constructor_teammate_gap_local;

DROP VIEW IF EXISTS dm.circuit_map;
CREATE VIEW dm.circuit_map AS
SELECT * FROM dm.circuit_map_local;

DROP VIEW IF EXISTS dm.podium;
CREATE VIEW dm.podium AS
SELECT * FROM dm.podium_local;


DROP VIEW IF EXISTS dm.pit_season;
CREATE VIEW dm.pit_season AS
SELECT * FROM dm.pit_season_local;

DROP VIEW IF EXISTS dm.flag_season;
CREATE VIEW dm.flag_season AS
SELECT * FROM dm.flag_season_local;