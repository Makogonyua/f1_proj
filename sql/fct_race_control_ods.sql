insert into ods.fct_race_control (
    session_key, meeting_key, date, category, flag, message, 
    driver_number, lap_number
)
select distinct
    session_key, meeting_key, date, category, flag, message, 
    driver_number, lap_number
from staging.fct_race_control
on conflict (meeting_key, session_key, date, flag, message, driver_number, lap_number) do nothing;