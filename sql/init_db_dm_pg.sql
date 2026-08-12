
create table if not exists dm.championship_standings (
	season int4 NULL,
	meeting_key int4 NULL,
	meeting_name varchar(255) NULL,
	meeting_date timestamp NULL,
	meeting_order int4 NULL,
	circuit_key int4 NULL,
	circuit_name text NULL,
	country_code varchar(10) NULL,
	session_key int4 NULL,
	session_type varchar(50) NULL,
	driver_number int4 NULL,
	name_acronym varchar(10) NULL,
	driver_name varchar(255) NULL,
	driver_country varchar(10) NULL,
	team_name varchar(100) NULL,
	position_current int4 NULL,
	position_start int4 NULL,
	points_current int4 NULL,
	points_start int4 NULL,
	points_earned int4 NULL,
	driver_headshot_url varchar(500) NULL
);

create table if not exists dm.circuit_map (
	circuit_key int4 NULL,
	circuit_name text NULL,
	latitude numeric(9, 6) NULL,
	longitude numeric(9, 6) NULL,
	country_code varchar(10) NULL,
	timezone varchar(50) NULL,
	meeting_key int4 NULL,
	meeting_name varchar(255) NULL,
	meeting_date timestamp NULL,
	season int4 NULL,
	meeting_order int4 NULL,
	is_cancelled bool NULL,
	is_future bool NULL,
	is_past bool NULL,
	race_status varchar(20) NULL
);

create table if not exists dm.constructor_podium (
	season int4 NULL,
	"position" int4 NULL,
	team_name varchar(100) NULL,
	total_points int4 NULL,
	wins int4 NULL,
	podiums int4 NULL
);

create table if not exists dm.constructor_standings (
	season int4 NULL,
	meeting_name varchar(255) NULL,
	team_name varchar(100) NULL,
	total_points numeric NULL,
	wins int8 NULL,
	podiums int8 NULL,
	drivers_count int8 NULL,
	date_start date NULL
);

create table if not exists dm.constructor_stats (
	team_name varchar(100) NULL,
	season int4 NULL,
	avg_finish_position numeric NULL,
	avg_start_position numeric NULL,
	total_dnf int8 NULL,
	total_entries int8 NULL,
	dnf_percentage numeric NULL
);

create table if not exists dm.constructor_teammate_gap (
	team_name varchar(100) NULL,
	season int4 NULL,
	meeting_name varchar(255) NULL,
	driver_1 varchar(10) NULL,
	driver_2 varchar(10) NULL,
	pos_driver_1 int4 NULL,
	pos_driver_2 int4 NULL,
	position_gap int4 NULL,
	winner varchar(10) NULL
);

create table if not exists dm.driver_lap_stats (
	driver_number int4 NULL,
	name_acronym varchar(10) NULL,
	driver_name varchar(255) NULL,
	team_name varchar(100) NULL,
	season int4 NULL,
	meeting_name varchar(255) NULL,
	session_type varchar(50) NULL,
	total_laps int8 NULL,
	avg_lap_time numeric NULL,
	best_lap_time numeric NULL,
	avg_sector_1 numeric NULL,
	avg_sector_2 numeric NULL,
	avg_sector_3 numeric NULL
);

create table if not exists dm.driver_profile (
	driver_number int4 NULL,
	name_acronym varchar(10) NULL,
	full_name varchar(255) NULL,
	country_code varchar(10) NULL,
	team_name varchar(100) NULL,
	season int4 NULL,
	total_sessions int8 NULL
);

create table if not exists dm.driver_race_stats (
	driver_number int4 NULL,
	name_acronym varchar(10) NULL,
	driver_name varchar(255) NULL,
	team_name varchar(100) NULL,
	season int4 NULL,
	meeting_name varchar(255) NULL,
	finish_position int4 NULL,
	start_position int4 NULL,
	number_of_laps int4 NULL,
	duration numeric NULL,
	gap_to_leader numeric NULL,
	status_code varchar(10) NULL,
	points int4 NULL,
	is_win int4 NULL,
	is_podium int4 NULL,
	is_dnf int4 NULL
);

create table if not exists dm.flag_season (
	season int4 NULL,
	circuit_name text NULL,
	yellow_flag int4 NULL,
	red_flag int4 NULL
);


create table if not exists dm.pit_season (
	season int4 NULL,
	circuit_name text NULL,
	team_name varchar(100) NULL,
	stop_duration float8 NULL
);


create table if not exists dm.podium (
	season int4 NULL,
	"position" int4 NULL,
	medal varchar(10) NULL,
	driver_name varchar(255) NULL,
	name_acronym varchar(10) NULL,
	team_name varchar(100) NULL,
	points int4 NULL,
	wins int4 NULL,
	podiums int4 NULL,
	driver_headshot_url varchar(500) NULL
);