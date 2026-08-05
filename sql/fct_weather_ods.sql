insert into ods.fct_weather (
    session_key, meeting_key, date, air_temperature, track_temperature,
    humidity, pressure, wind_speed, wind_direction, rainfall
)
select distinct
    session_key, meeting_key, date, air_temperature, track_temperature,
    humidity, pressure, wind_speed, wind_direction, rainfall
from staging.fct_weather
on conflict (session_key, meeting_key, date) do nothing;