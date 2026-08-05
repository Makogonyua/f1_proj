insert into ods.fct_overtakes (
    meeting_key, session_key, overtaking_driver_number, 
    overtaken_driver_number, date, position
)
select distinct
    meeting_key, session_key, overtaking_driver_number, 
    overtaken_driver_number, date, position
from staging.fct_overtakes


on conflict (meeting_key, session_key, overtaking_driver_number, overtaken_driver_number) do nothing;
