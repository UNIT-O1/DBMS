-- 1d(ii). Total daily ad views (all statuses) across the window. Anomalies are FLAGGED, not dropped,
-- so the chart and the table show what was actually logged.
--   in_gap            : 2026-03-05..07 telemetry outage (players were still active and buying)
--   sentinel_ts_rows  : events stamped exactly 07:59:56 (a fixed timestamp, date still trustworthy)
--   out_of_window     : events after 2026-04-30 (partial trailing day)
select event_date,
       count(*) as views,
       count(*) filter (where status = 'completed') as completed,
       count(*) filter (where is_sentinel_ts) as sentinel_ts_rows,
       count(distinct player_id) as players_watching,
       bool_or(in_ad_gap) as in_gap,
       bool_or(out_of_window) as out_of_window
from ad
group by event_date
order by event_date;
