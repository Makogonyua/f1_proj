insert into ods.fct_championship_teams (
    session_key, meeting_key, team_name, position_current, 
    position_start, points_current, points_start
)
select distinct
    session_key, meeting_key, team_name, position_current, 
    position_start, points_current, points_start
from staging.fct_championship_teams
on conflict (session_key, team_name) do nothing;