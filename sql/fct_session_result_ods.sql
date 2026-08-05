insert into ods.fct_session_result (
    session_key, meeting_key, driver_number, position, number_of_laps,
    duration, gap_to_leader, dnf, dns, dsq, points
)
select distinct
    session_key, meeting_key, driver_number, position, number_of_laps,
    duration, gap_to_leader, dnf, dns, dsq, points
from staging.fct_session_result
on conflict (session_key, driver_number) do nothing;