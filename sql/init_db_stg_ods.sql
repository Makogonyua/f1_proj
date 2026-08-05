create schema if not exists staging;

create schema if not exists ods;


create table if not exists staging.dim_driver (
	driver_number int4,
	broadcast_name varchar(255),
	first_name varchar(100),
	last_name varchar(100),
	full_name varchar(255),
	name_acronym varchar(10),
	country_code varchar(10),
	team_name varchar(100),
	team_colour varchar(10),
	headshot_url varchar(500),
	primary key (driver_number)
);

create table if not exists staging.dim_meeting (
	meeting_key int4,
	meeting_name varchar(255),
	country_name varchar(100),
	country_code varchar(10),
	circuit_key int4,
	circuit_short_name varchar(255),
	date_start timestamp,
	"year" int4,
	primary key (meeting_key) 
);

create table if not exists staging.dim_session (
	session_key int4,
	meeting_key int4,
	session_name varchar(100),
	session_type varchar(50),
	date_start timestamp,
	date_end timestamp,
	is_cancelled bool,
	primary key (session_key)
);

create table if not exists staging.fct_championship_drivers (
	session_key numeric,
	meeting_key numeric,
	driver_number numeric,
	position_current numeric,
	position_start numeric,
	points_current numeric,
	points_start numeric,
    primary key (session_key, driver_number)
);

create table if not exists staging.fct_championship_teams (
	session_key numeric,
	meeting_key numeric,
	team_name varchar(100),
	position_current numeric,
	position_start numeric,
	points_current numeric,
	points_start numeric,
	primary key (session_key, team_name)
);

create table if not exists staging.fct_laps (
	session_key int4,
	meeting_key int4,
	driver_number int4,
	lap_number int4,
	lap_duration float8,
	duration_sector_1 float8,
	duration_sector_2 float8,
	duration_sector_3 float8,
	stint_number int4,
	compound varchar(50),
	tyre_age_at_start int4,
	is_pit_out_lap bool,
	primary key (session_key, driver_number, lap_number)
);

create table if not exists staging.fct_overtakes (
	meeting_key int4,
	session_key int4,
	overtaking_driver_number int4,
	overtaken_driver_number numeric,
	"date" timestamp,
	"position" numeric 
);

create table if not exists staging.fct_pit (
	session_key int4,
	meeting_key int4,
	driver_number int4,
	lap_number int4,
	pit_duration float8,
	primary key (session_key, driver_number, lap_number)
);

create table if not exists staging.fct_position (
	session_key int4,
	meeting_key int4,
	driver_number int4,
	"position" int4,
	"date" timestamp 
);

create table if not exists staging.fct_race_control (
	session_key numeric,
	meeting_key numeric,
	"date" timestamp,
	category varchar(50),
	flag varchar(50),
	message text,
	driver_number numeric,
	lap_number numeric 
);

create table if not exists staging.fct_session_result (
	session_key numeric,
	meeting_key numeric,
	driver_number numeric,
	"position" numeric,
	number_of_laps numeric,
	duration float8,
	gap_to_leader float8,
	dnf varchar(40),
	dns bool,
	dsq bool,
	points numeric,
	primary key (session_key, driver_number)
);

create table if not exists staging.fct_starting_grid (
	session_key int4,
	meeting_key int4,
	driver_number int4,
	"position" int4,
	lap_duration float8,
	primary key (session_key, driver_number)
);

create table if not exists staging.fct_stints (
	session_key numeric,
	meeting_key numeric,
	driver_number numeric,
	stint_number numeric,
	lap_start numeric,
	lap_end numeric,
	compound varchar(50),
	tyre_age_at_start numeric,
	constraint fct_stints_pkey primary key (session_key, driver_number, stint_number)
);

create table if not exists staging.fct_weather (
	session_key int4,
	meeting_key int4,
	"date" timestamp,
	air_temperature float8,
	track_temperature float8,
	humidity float8,
	pressure float8,
	wind_speed float8,
	wind_direction float8,
	rainfall int4 
);
---------------------STG
create table if not exists ods.dim_driver (
	driver_number int4,
	broadcast_name varchar(255),
	first_name varchar(100),
	last_name varchar(100),
	full_name varchar(255),
	name_acronym varchar(10),
	country_code varchar(10),
	team_name varchar(100),
	team_colour varchar(10),
	headshot_url varchar(500),
	primary key (driver_number)
);

create table if not exists ods.dim_meeting (
	meeting_key int4,
	meeting_name varchar(255),
	country_name varchar(100),
	country_code varchar(10),
	circuit_key int4,
	circuit_short_name varchar(255),
	date_start timestamp,
	"year" int4,
	primary key (meeting_key)
);

create table if not exists ods.dim_session (
	session_key int4,
	meeting_key int4,
	session_name varchar(100),
	session_type varchar(50),
	date_start timestamp,
	date_end timestamp,
	is_cancelled bool,
	primary key (session_key)
);

create table if not exists ods.fct_championship_drivers (
	session_key numeric,
	meeting_key numeric,
	driver_number numeric,
	position_current numeric,
	position_start numeric,
	points_current numeric,
	points_start numeric,
	primary key (session_key, driver_number)
);

create table if not exists ods.fct_championship_teams (
	session_key numeric,
	meeting_key numeric,
	team_name varchar(100),
	position_current numeric,
	position_start numeric,
	points_current numeric,
	points_start numeric,
	primary key (session_key, team_name)
);

create table if not exists ods.fct_laps (
	session_key int4,
	meeting_key int4,
	driver_number int4,
	lap_number int4,
	lap_duration float8,
	duration_sector_1 float8,
	duration_sector_2 float8,
	duration_sector_3 float8,
	stint_number int4,
	compound varchar(50),
	tyre_age_at_start int4,
	is_pit_out_lap bool,
	primary key (session_key, driver_number, lap_number)
);

create table if not exists ods.fct_overtakes (
	meeting_key int4,
	session_key int4,
	overtaking_driver_number int4,
	overtaken_driver_number numeric,
	"date" timestamp,
	"position" numeric,
	primary key (meeting_key, session_key, overtaking_driver_number, overtaken_driver_number)
);

create table if not exists ods.fct_pit (
	session_key int4,
	meeting_key int4,
	driver_number int4,
	lap_number int4,
	pit_duration float8,
	primary key (session_key, driver_number, lap_number)
);

create table if not exists ods.fct_position (
	session_key int4,
	meeting_key int4,
	driver_number int4,
	"position" int4,
	"date" timestamp,
	primary key (meeting_key, session_key, driver_number)
);

create table if not exists ods.fct_race_control (
	session_key numeric,
	meeting_key numeric,
	"date" timestamp,
	category varchar(50),
	flag varchar(50),
	message text,
	driver_number numeric,
	lap_number numeric,
	primary key (meeting_key, session_key, date, flag, message, driver_number, lap_number)
);

create table if not exists ods.fct_session_result (
	session_key numeric,
	meeting_key numeric,
	driver_number numeric,
	"position" numeric,
	number_of_laps numeric,
	duration float8,
	gap_to_leader float8,
	dnf varchar(40),
	dns bool,
	dsq bool,
	points numeric,
	primary key (session_key, driver_number)
);

create table if not exists ods.fct_starting_grid (
	session_key int4,
	meeting_key int4,
	driver_number int4,
	"position" int4,
	lap_duration float8,
	primary key (session_key, driver_number)
);

create table if not exists ods.fct_stints (
	session_key numeric,
	meeting_key numeric,
	driver_number numeric,
	stint_number numeric,
	lap_start numeric,
	lap_end numeric,
	compound varchar(50),
	tyre_age_at_start numeric,
	primary key (session_key, driver_number, stint_number)
);

create table if not exists ods.fct_weather (
	session_key int4,
	meeting_key int4,
	"date" timestamp,
	air_temperature float8,
	track_temperature float8,
	humidity float8,
	pressure float8,
	wind_speed float8,
	wind_direction float8,
	rainfall int4,
	primary key (session_key, meeting_key, date)
);