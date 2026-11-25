-- 1b. Retention grid. Cohort = install week (Monday start), installs from 2026-01-01 onward.
-- Why installs >= 2026-01-01: earlier installs have their first days BEFORE the telemetry starts,
-- so day-1/7/14/30 would be silently missing rather than churned.
-- Active on day N = any player_day row on exactly install_date + N.
-- Maturity rule: a cell is shown only if every install in that week has reached day N by 2026-04-30
-- (max(install_date) + N <= 2026-04-30). Partly-observed cells are blank, not low.
with cohort as (
    select player_id, install_date,
           date_trunc('week', install_date)::date as cohort_week
    from player
    where install_date between date '2026-01-01' and date '2026-04-30'
),
per_player as (
    select c.cohort_week, c.player_id, c.install_date,
           bool_or(a.activity_date = c.install_date + 1)  as d1,
           bool_or(a.activity_date = c.install_date + 7)  as d7,
           bool_or(a.activity_date = c.install_date + 14) as d14,
           bool_or(a.activity_date = c.install_date + 30) as d30
    from cohort c
    left join pd a
      on a.player_id = c.player_id
     and a.activity_date between c.install_date + 1 and c.install_date + 30
    group by all
)
select cohort_week,
       count(*) as cohort_size,
       round(case when max(install_date) + 1  <= date '2026-04-30' then avg(d1::int)  end, 3) as d1,
       round(case when max(install_date) + 7  <= date '2026-04-30' then avg(d7::int)  end, 3) as d7,
       round(case when max(install_date) + 14 <= date '2026-04-30' then avg(d14::int) end, 3) as d14,
       round(case when max(install_date) + 30 <= date '2026-04-30' then avg(d30::int) end, 3) as d30
from per_player
group by cohort_week
order by cohort_week;
