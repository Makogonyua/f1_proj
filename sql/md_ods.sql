insert into ods.dim_driver (
    driver_number, broadcast_name, first_name, last_name, full_name, 
    name_acronym, country_code, team_name, team_colour, headshot_url
)
select distinct
    driver_number, broadcast_name, first_name, last_name, full_name, 
    name_acronym, country_code, team_name, team_colour, headshot_url
from staging.dim_driver
on conflict (driver_number) do nothing;

insert into ods.dim_meeting (
    meeting_key, meeting_name, country_name, country_code, 
    circuit_key, circuit_short_name, date_start, year
)
select distinct
    meeting_key, meeting_name, country_name, country_code, 
    circuit_key, circuit_short_name, date_start, year
from staging.dim_meeting
on conflict (meeting_key) do nothing;

insert into ods.dim_session (
    session_key, meeting_key, session_name, session_type, 
    date_start, date_end, is_cancelled
)
select distinct
    session_key, meeting_key, session_name, session_type, 
    date_start, date_end, is_cancelled
from staging.dim_session
on conflict (session_key) do nothing;