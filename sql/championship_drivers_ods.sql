insert into ods.fct_championship_drivers (
    session_key, meeting_key, driver_number, position_current, 
    position_start, points_current, points_start
)
select distinct
    session_key, meeting_key, driver_number, position_current, 
    position_start, points_current, points_start
from staging.fct_championship_drivers
on conflict (session_key, driver_number) do nothing;