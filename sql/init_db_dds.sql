
create table if not exists dds.championship_drivers (
	session_key int4 NOT NULL,
	driver_number int4 NOT NULL,
	position_current int4 NULL,
	position_start int4 NULL,
	points_current int4 NULL,
	points_start int4 NULL,
	CONSTRAINT championship_drivers_pkey PRIMARY KEY (session_key, driver_number)
);



create table if not exists dds.laps (
	session_key int4 NOT NULL,
	driver_number int4 NOT NULL,
	lap_number int4 NOT NULL,
	stint_number int4 NULL,
	lap_duration numeric(17, 3) NULL,
	duration_sector_1 numeric(17, 3) NULL,
	duration_sector_2 numeric(17, 3) NULL,
	duration_sector_3 numeric(17, 3) NULL,
	is_pit_out_lap bool DEFAULT false NULL,
	CONSTRAINT laps_pkey PRIMARY KEY (session_key, driver_number, lap_number)
);


create table if not exists dds.overtakes (
	session_key int4 NOT NULL,
	driver_number int4 NOT NULL,
	overtaking_driver_number int4 NOT NULL,
	lap_number int4 NOT NULL,
	ts timestamp NULL,
	CONSTRAINT overtakes_pkey PRIMARY KEY (session_key, driver_number, overtaking_driver_number, lap_number)
);


create table if not exists dds.pit (
	session_key int4 NOT NULL,
	driver_number int4 NOT NULL,
	lap_number int4 NOT NULL,
	pit_duration numeric NULL,
	CONSTRAINT fct_pit_pkey PRIMARY KEY (session_key, driver_number, lap_number)
);


create table if not exists dds."position" (
	session_key int4 NOT NULL,
	driver_number int4 NOT NULL,
	ts timestamp NOT NULL,
	"position" int4 NOT NULL,
	CONSTRAINT position_pkey PRIMARY KEY (session_key, driver_number, ts)
);


create table if not exists dds.r_circuit (
	circuit_key int4 NOT NULL,
	circuit_name text NOT NULL,
	country_code varchar(10) NOT NULL,
	CONSTRAINT r_circuit_pkey PRIMARY KEY (circuit_key)
);



create table if not exists dds.r_driver (
	full_name varchar(255) NULL,
	name_acronym varchar(10) NOT NULL,
	country_code varchar(10) NULL,
	team_name varchar(100) NULL,
	CONSTRAINT r_driver_pkey PRIMARY KEY (name_acronym)
);



create table if not exists dds.r_driver_season (
	season date NOT NULL,
	driver_number int4 NOT NULL,
	name_acronym varchar(10) NULL,
	CONSTRAINT r_driver_season_pkey PRIMARY KEY (season, driver_number)
);


create table if not exists dds.r_meeting (
	meeting_key int4 NOT NULL,
	meeting_name varchar(255) NULL,
	circuit_key int4 NULL,
	date_start timestamp NULL,
	CONSTRAINT r_meeting_pkey PRIMARY KEY (meeting_key)
);


create table if not exists dds.r_session (
	session_key int4 NOT NULL,
	meeting_key int4 NULL,
	date_start timestamp NULL,
	date_end timestamp NULL,
	is_cancelled bool DEFAULT false NULL,
	session_type varchar(50) NULL,
	session_name varchar(100),
	CONSTRAINT r_session_pkey PRIMARY KEY (session_key)
);


create table if not exists dds.r_session_type (
	session_type varchar(50) NOT NULL,
	session_name text NULL,
	CONSTRAINT r_session_type_pkey PRIMARY KEY (session_type)
);


create table if not exists dds.r_status (
	status_code varchar(10) NOT NULL,
	status_name varchar(50) NULL,
	CONSTRAINT r_status_pkey PRIMARY KEY (status_code)
);


create table if not exists dds.race_control (
	session_key int4 NOT NULL,
	ts timestamp NOT NULL,
	category varchar(50) NULL,
	flag varchar(50) NOT NULL,
	message text NOT NULL,
	driver_number int4 NOT NULL,
	lap_number int4 NOT NULL,
	CONSTRAINT race_control_pkey PRIMARY KEY (session_key, ts, message)
);

create table if not exists dds.weather (
	session_key int4 NOT NULL,
	ts timestamp NOT NULL,
	air_temperature numeric NULL,
	track_temperature numeric NULL,
	humidity numeric NULL,
	pressure numeric NULL,
	wind_speed numeric NULL,
	rainfall bool DEFAULT false NULL,
	CONSTRAINT weather_pkey PRIMARY KEY (session_key, ts)
);


create table if not exists dds.session_result (
    session_key int4 NOT NULL,
    driver_number int4 NOT NULL,
    "position" int4 NULL,
    number_of_laps int4 NULL,
    duration numeric(17, 3) NULL,
    gap_to_leader numeric(17, 3) NULL,
    status_code varchar(10) NULL,
    points int4 NULL,
    CONSTRAINT session_result_pkey PRIMARY KEY (session_key, driver_number)
);