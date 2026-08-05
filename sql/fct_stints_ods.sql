insert into ods.fct_stints (
    session_key, meeting_key, driver_number, stint_number, 
    lap_start, lap_end, compound, tyre_age_at_start
)
select distinct
    session_key, meeting_key, driver_number, stint_number, 
    lap_start, lap_end, compound, tyre_age_at_start
from staging.fct_stints
on conflict (session_key, driver_number, stint_number) do nothing;