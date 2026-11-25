-- 1c(iii). Repeat purchase gap: time between CONSECUTIVE positive purchases by the same player.
-- LAG window over (player, event_ts). Refund rows are excluded from the sequence.
-- Gap is fractional days from event_ts, so same-day repeats are not rounded to zero.
with pos as (
    select player_id, event_ts,
           lag(event_ts) over (partition by player_id order by event_ts) as prev_ts
    from pu
    where usd_amount > 0
),
gaps as (
    select player_id, date_diff('second', prev_ts, event_ts) / 86400.0 as gap_days
    from pos
    where prev_ts is not null
)
select count(*)                                  as repeat_purchases,
       count(distinct player_id)                 as repeat_buyers,
       round(quantile_cont(gap_days, 0.10), 2)   as p10_days,
       round(quantile_cont(gap_days, 0.25), 2)   as p25_days,
       round(quantile_cont(gap_days, 0.50), 2)   as median_days,
       round(quantile_cont(gap_days, 0.75), 2)   as p75_days,
       round(quantile_cont(gap_days, 0.90), 2)   as p90_days,
       round(avg(case when gap_days < 1 then 1 else 0 end), 4) as share_within_1_day,
       round(avg(case when gap_days <= 7 then 1 else 0 end), 4) as share_within_7_days
from gaps;
