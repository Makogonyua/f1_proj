insert into ods.fct_pit (
    session_key, meeting_key, driver_number, lap_number, pit_duration
)
select distinct
    session_key, meeting_key, driver_number, lap_number, pit_duration
from staging.fct_pit
on conflict (session_key, driver_number, lap_number) do nothing;