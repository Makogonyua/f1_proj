insert into ods.fct_laps (
    session_key, meeting_key, driver_number, lap_number, lap_duration,
    duration_sector_1, duration_sector_2, duration_sector_3,
    stint_number, compound, tyre_age_at_start, is_pit_out_lap
)
select distinct
    session_key, meeting_key, driver_number, lap_number, lap_duration,
    duration_sector_1, duration_sector_2, duration_sector_3,
    stint_number, compound, tyre_age_at_start, is_pit_out_lap
from staging.fct_laps
on conflict (session_key, driver_number, lap_number) do nothing;