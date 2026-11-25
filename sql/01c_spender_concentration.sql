-- 1c(i). Revenue concentration. Gross revenue per player = sum of positive purchases, Jan-Apr 2026.
-- Two populations, both reported, because they answer different questions:
--   payers   : rank only players with gross > 0 -> share of PAYER revenue held by top x% of payers
--   everyone : rank all merged players          -> share of TOTAL revenue held by top x% of all players
-- Buckets are ntile(1000) so 1% = bucket 1..10 and 10% = bucket 1..100 (top 50% = 1..500).
with per_player as (
    select p.player_id,
           coalesce(sum(pu.usd_amount) filter (where pu.usd_amount > 0), 0) as gross
    from player p left join pu using (player_id)
    group by 1
),
payers as (select * from per_player where gross > 0),
ranked_payers as (select gross, ntile(1000) over (order by gross desc) as bucket from payers),
ranked_all    as (select gross, ntile(1000) over (order by gross desc) as bucket from per_player),
totals as (
    select (select sum(gross) from payers)     as payer_total,
           (select sum(gross) from per_player) as all_total,
           (select count(*) from payers)       as n_payers,
           (select count(*) from per_player)   as n_players
)
select 'payers' as population, t.n_payers as population_size,
       round(sum(gross) filter (where bucket <= 10)  / t.payer_total, 4) as top_1pct_share,
       round(sum(gross) filter (where bucket <= 100) / t.payer_total, 4) as top_10pct_share,
       round(sum(gross) filter (where bucket <= 500) / t.payer_total, 4) as top_50pct_share
from ranked_payers, totals t
group by t.n_payers, t.payer_total
union all
select 'everyone', t.n_players,
       round(sum(gross) filter (where bucket <= 10)  / t.all_total, 4),
       round(sum(gross) filter (where bucket <= 100) / t.all_total, 4),
       round(sum(gross) filter (where bucket <= 500) / t.all_total, 4)
from ranked_all, totals t
group by t.n_players, t.all_total;
