-- 1c(ii). Time to first purchase, for the JANUARY 2026 install cohort only.
-- Right-censoring: a player installed on Apr 20 has 10 days of history, so a distribution over all
-- installs would make recent players look like non-payers. Jan installs have >= 89 days observed
-- to Apr 30, so a 90-day window is complete for them.
-- Measured from install_date (day 0) to the first purchase with a positive amount.
with cohort as (
    select player_id, install_date from player
    where install_date between date '2026-01-01' and date '2026-01-31'
),
first_buy as (
    select c.player_id, c.install_date,
           min(pu.purchase_date) as first_purchase_date
    from cohort c
    left join pu on pu.player_id = c.player_id and pu.usd_amount > 0
    group by 1, 2
),
days as (
    select first_purchase_date - install_date as days from first_buy
)
select
    case
      when days is null then '6. never paid (in window)'
      when days = 0 then '0. same day'
      when days = 1 then '1. day 1'
      when days between 2 and 6 then '2. days 2-6'
      when days between 7 and 29 then '3. days 7-29'
      when days between 30 and 89 then '4. days 30-89'
      else '5. 90+' end as bucket,
    count(*) as players,
    round(count(*) * 1.0 / sum(count(*)) over (), 4) as share_of_cohort
from days
group by 1
order by 1;
