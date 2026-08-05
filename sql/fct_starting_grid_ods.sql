insert into ods.fct_starting_grid (
    session_key, meeting_key, driver_number, position, lap_duration
)
select distinct
    session_key, meeting_key, driver_number, position, lap_duration
from staging.fct_starting_grid
on conflict (session_key, driver_number) do nothing;