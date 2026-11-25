-- 1d(i). Share of ad-watching player-days that hit the daily cap, broken out by cap value.
-- Unit = player-day with at least one ad row.
-- Hit cap = max(ad_daily_count) that day >= ad_daily_cap.
-- Excluded: the ad telemetry gap (2026-03-05..07) and out-of-window rows (after 2026-04-30).
with ad_days as (
    select player_id, event_date,
           max(ad_daily_count) as max_count,
           max(ad_daily_cap)   as cap,
           count(*) filter (where status = 'completed') as completed
    from ad
    where not in_ad_gap and not out_of_window
    group by 1, 2
)
select cap as ad_daily_cap,
       count(*) as ad_player_days,
       count(*) filter (where max_count >= cap) as days_hit_cap,
       round(count(*) filter (where max_count >= cap) * 1.0 / count(*), 4) as share_hit_cap,
       round(avg(completed), 2) as avg_completed_views_per_day,
       round(avg(max_count), 2) as avg_max_count
from ad_days
group by cap
order by cap;
