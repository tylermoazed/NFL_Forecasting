with games_winners_total as (
SELECT
	a.schedule_date
	,a.schedule_season
	,case
		when a.schedule_week in ('Wildcard','WildCard') and a.schedule_season < 2021 then 18
		when a.schedule_week in ('Wildcard','WildCard') and a.schedule_season >= 2021 then 19
		when a.schedule_week = 'Division' and a.schedule_season < 2021 then 19
		when a.schedule_week = 'Division' and a.schedule_season >= 2021 then 20
		when a.schedule_week = 'Conference' and a.schedule_season < 2021 then 20
		when a.schedule_week = 'Conference' and a.schedule_season >= 2021 then 21
		when a.schedule_week in ('Superbowl','SuperBowl') and a.schedule_season < 2021 then 21
		when a.schedule_week in ('Superbowl','SuperBowl') and a.schedule_season >= 2021 then 22
	  	else a.schedule_week::int end as schedule_week
	,b.team_id as team_home_id
	,c.team_id as team_away_id
from nfl_games_66_22_map a
	left join nfl_team_name_map b on a.team_home = b.team_name
	left join nfl_team_name_map c on a.team_away = c.team_name
where schedule_season >= 2000
order by schedule_date asc
),
elo_base as(
SELECT 
	gwt.*
	,elo.score1 as score_home
	,elo.score2 as score_away
	,(elo.score1 + elo.score2) as total
	,case
		when elo.score1 > elo.score2 then 1
		when elo.score2 > elo.score1 then 0
		when elo.score2 = elo.score1 then 0
		else null end as home_team_win
	,case
		when elo.score1 > elo.score2 then gwt.team_home_id
		when elo.score2 > elo.score1 then gwt.team_away_id
		when elo.score2 = elo.score1 then 'tie'
		else null end as winning_team_id
	,case
		when elo.score1 > elo.score2 then elo.score1 - elo.score2
		when elo.score2 > elo.score1 then elo.score2 - elo.score1
		when elo.score1 = elo.score2 then 0
		end as winning_team_margin 
	,elo.neutral
	,elo.playoff
	,elo.elo1_pre as elo_home_pre
	,elo.elo2_pre as elo_away_pre
	,elo.qb1_value_pre as home_qb_value_pre
	,elo.qb2_value_pre as away_qb_value_pre
	,elo.qb1_adj as home_qb_adj
	,elo.qb2_adj as away_qb_adj
from games_winners_total gwt
	left join elo_1920_2022 elo on gwt.schedule_date = elo.date and gwt.team_home_id = elo.team1 and gwt.team_away_id = elo.team2
),
score as (
SELECT 
team_home_id as team_id
,schedule_season
,schedule_week
,sum(score_home) as score
from elo_base
group by 1,2,3
--order by schedule_season asc, schedule_week asc, team_home_id

UNION ALL

SELECT 
team_away_id as team_id
,schedule_season
,schedule_week
,sum(score_away) as score
from elo_base
group by 1,2,3
order by schedule_season asc, schedule_week asc, team_id
),
simple_average as (
SELECT
*
,AVG(score) OVER (PARTITION BY team_id,schedule_season ORDER BY schedule_season asc, schedule_week asc ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS sma
from score
),
lag_sma as (
SELECT
*
,lag(sma) over (PARTITION BY team_id ORDER BY schedule_season asc, schedule_week asc) as shift_sma
from simple_average
),
ewma as ( SELECT
*
,ROUND((((score - shift_sma) * 0.4) + shift_sma), 2) AS ewma
from lag_sma ),
lag_ewma as (
SELECT
*
,lag(ewma) over (PARTITION BY team_id ORDER BY schedule_season asc, schedule_week asc) as shift_ewma
from ewma
),
forecast_emwa as (
SELECT 
team_id
,schedule_season
,schedule_week
,score
,sma
,ewma as ewma_type1
,ROUND((((score - shift_ewma) * 0.4) + shift_ewma), 2) AS ewma_type2
,lag(ROUND((((score - shift_ewma) * 0.4) + shift_ewma), 2)) OVER (PARTITION BY team_id ORDER BY schedule_season asc, schedule_week asc) as forecast_ewma
from lag_ewma
),
final_score_forecast as (
SELECT 
team_id
,schedule_season
,schedule_week
,score
,coalesce(forecast_ewma,ewma_type1) as score_forecast
from forecast_emwa
),
elo_base_and_score_forecast as (
SELECT 
b.schedule_date
,b.schedule_season
,b.schedule_week
,b.team_home_id
,b.team_away_id
,b.score_home
,b.score_away
,b.total
,b.home_team_win
,b.winning_team_id
,b.winning_team_margin
,b.neutral
,b.playoff
,b.elo_home_pre
,b.elo_away_pre
,b.home_qb_value_pre
,b.away_qb_value_pre
,b.home_qb_adj
,b.away_qb_adj
,h.team_id as fore_home_team
,h.score as fore_home_score
,h.score_forecast as home_score_forecast
,a.team_id as fore_away_team
,a.score as fore_away_score
,a.score_forecast as away_score_forecast
from elo_base b
	left join final_score_forecast h on b.schedule_season = h.schedule_season and b.schedule_week = h.schedule_week and b.team_home_id = h.team_id
	left join final_score_forecast a on b.schedule_season = a.schedule_season and b.schedule_week = a.schedule_week and b.team_away_id = a.team_id
),
dvoa as (
SELECT 
	b.*
	,cast(split_part(h.w_l, '-', 1) AS INTEGER) as home_wins
	,cast(split_part(a.w_l, '-', 1) AS INTEGER) as away_wins
	,cast(split_part(h.w_l, '-', 2) AS INTEGER) as home_losses
	,cast(split_part(a.w_l, '-', 2) AS INTEGER) as away_losses
	,cast(split_part(h.w_l, '-', 3) AS INTEGER) as home_ties
	,cast(split_part(a.w_l, '-', 3) AS INTEGER) as away_ties
	,h.total_dvoa_rank as home_total_dvoa_rank
	,a.total_dvoa_rank as away_total_dvoa_rank
	,h.total_dvoa as home_total_dvoa
	,a.total_dvoa as away_total_dvoa
	,h.weighted_dvoa_rank as home_weighted_total_dvoa_rank
	,a.weighted_dvoa_rank as away_weighted_total_dvoa_rank
	,h.weighted_dvoa as home_total_weighted_dvoa
	,a.weighted_dvoa as away_total_weighted_dvoa
	,h.off_dvoa_rank as home_off_dvoa_rank
	,a.off_dvoa_rank as away_off_dvoa_rank
	,h.off_dvoa as home_off_dvoa
	,a.off_dvoa as away_off_dvoa
	,h.off_weighted_dvoa_rank as home_weighted_off_dvoa_rank
	,a.off_weighted_dvoa_rank as away_weighted_off_dvoa_rank
	,h.off_weighted_dvoa as home_off_weighted_dvoa
	,a.off_weighted_dvoa as away_off_weighted_dvoa
	,h.def_dvoa_rank as home_def_dvoa_rank
	,a.def_dvoa_rank as away_def_dvoa_rank
	,h.def_dvoa as home_def_dvoa
	,a.def_dvoa as away_def_dvoa
	,h.def_weighted_dvoa_rank as home_weighted_def_dvoa_rank
	,a.def_weighted_dvoa_rank as away_weighted_def_dvoa_rank
	,h.def_weighted_dvoa as home_def_weighted_dvoa
	,a.def_weighted_dvoa as away_def_weighted_dvoa
	,h.st_dvoa_rank as home_st_dvoa_rank
	,a.st_dvoa_rank as away_st_dvoa_rank
	,h.st_dvoa as home_st_dvoa
	,a.st_dvoa as away_st_dvoa
	,h.st_weighted_dvoa_rank as home_weighted_st_dvoa_rank
	,a.st_weighted_dvoa_rank as away_weighted_st_dvoa_rank
	,h.st_weighted_dvoa as home_st_weighted_dvoa
	,a.st_weighted_dvoa as away_st_weighted_dvoa
from elo_base_and_score_forecast b
	left join dvoa_00_22 h on b.schedule_season = h.season and b.schedule_week = h.week and b.team_home_id = h.team
	left join dvoa_00_22 a on b.schedule_season = a.season and b.schedule_week = a.week and b.team_away_id = a.team
order by schedule_date asc
),
vegas_updated as (
	SELECT 
	v1.*
	,v2.home_team_spread as home_team_spread_update
	,v2.over_under_line as over_under_line_update
from nfl_games_odds_weather_66_22 v1
	left join nfl_vegas_22_updated v2
	on v1.schedule_date = v2.schedule_date and v1.team_home = v2.team_home and v1.team_away = v2.team_away
),
vegas_map as (
SELECT 
	v.schedule_date
	,v.schedule_season
	,v.schedule_week
	,concat_ws('_',schedule_season,schedule_week) as season_week
	,h.team_id as team_home_id
	,a.team_id as team_away_id
	,trim(v.team_favorite_id) as team_favorite_id
	,v.spread_favorite
	,v.home_team_spread_update
	,coalesce(v.over_under_line,v.over_under_line_update) as over_under_line
from vegas_updated v
	left join nfl_team_name_map h on v.team_home = h.team_name
	left join nfl_team_name_map a on v.team_away = a.team_name 
where v.schedule_season >= 2000
order by schedule_date asc
),
vegas_enriched as (
	SELECT
	*
	,case
		when team_favorite_id = team_home_id then spread_favorite
		when team_favorite_id = team_away_id then (-1 * spread_favorite)
		when team_favorite_id = 'PICK' then 0
	end as home_team_spread
from vegas_map
),
vegas as (
SELECT
	schedule_date
	,schedule_season
	,schedule_week
	,season_week
	,team_home_id
	,team_away_id
	,coalesce(home_team_spread,home_team_spread_update) as home_team_spread
	,over_under_line
from vegas_enriched
order by schedule_date asc
),
basic_table as (
SELECT 
	d.*
	,v.over_under_line
	,v.season_week
   ,case
   		when total < over_under_line then 1
		when total >= over_under_line then 0
		end as under_cover
	,v.home_team_spread
	,case 
		when (home_team_spread + score_home) > score_away then 1
		when (home_team_spread + score_home) <= score_away then 0
		end as home_cover
from dvoa d
	left join vegas v on d.schedule_date = v.schedule_date and d.team_home_id = v.team_home_id and d.team_away_id = v.team_away_id
--where elo_home_pre isnull
order by schedule_date asc
)
SELECT
	schedule_date
	,schedule_season
	,schedule_week
	,season_week
	,team_home_id
	,team_away_id
	,score_home
	,score_away
	,total
	,home_team_win
	,elo_home_pre
	,elo_away_pre
	,elo_home_pre - elo_away_pre as matchup_h_a_delta_elo_pre
	,home_qb_value_pre
	,away_qb_value_pre
	,home_qb_value_pre - away_qb_value_pre as matchup_h_a_delta_qb_value_pre
	,home_qb_adj
	,away_qb_adj
	,home_qb_adj - away_qb_adj as matchup_h_a_delta_qb_adj
	,home_score_forecast as score_home_ewma
	,away_score_forecast as score_away_ewma
	,home_wins
	,away_wins
	,home_wins - away_wins as matchup_h_a_delta_wins
	,home_losses
	,away_losses
	,home_losses - away_losses as matchup_h_a_delta_losses
	,home_total_weighted_dvoa as h_tot_wght_dvoa
	,away_total_weighted_dvoa as a_tot_wght_dvoa
	,home_total_weighted_dvoa - away_total_weighted_dvoa as matchup_h_a_delta_tot_wght_dvoa
	,home_off_weighted_dvoa as h_off_wght_dvoa
	,away_off_weighted_dvoa as a_off_wght_dvoa
	,home_off_weighted_dvoa - away_off_weighted_dvoa as matchup_h_a_delta_off_wght_dvoa
	,home_def_weighted_dvoa as h_def_wght_dvoa
	,away_def_weighted_dvoa as a_def_wght_dvoa
	,home_def_weighted_dvoa - away_def_weighted_dvoa as matchup_h_a_delta_def_wght_dvoa
	,home_st_weighted_dvoa as h_st_wght_dvoa
	,away_st_weighted_dvoa as a_st_wght_dvoa
	,home_st_weighted_dvoa - away_st_weighted_dvoa as matchup_h_a_delta_st_wght_dvoa
	,over_under_line
	,under_cover
	,home_team_spread
	,home_cover
from basic_table
where home_total_weighted_dvoa notnull
and elo_home_pre notnull
and home_score_forecast notnull
and away_score_forecast notnull
order by schedule_date asc