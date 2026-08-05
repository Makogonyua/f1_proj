insert into ods.fct_position (
    session_key, meeting_key, driver_number, position, date
)
select distinct
    session_key, meeting_key, driver_number, position, date
from staging.fct_position
on conflict (meeting_key, session_key, driver_number) do nothing;