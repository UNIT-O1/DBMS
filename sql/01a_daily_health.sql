-- 1a. Daily health, split by platform (Jan 1 - Apr 30 2026).
-- DAU            = distinct merged players with a player_day row that calendar day.
-- Gross revenue  = sum of positive purchases dated that day (refunds reported separately).
-- ARPDAU         = gross revenue / DAU. Numerator includes ALL gross revenue that day, incl. from
--                  payers who were not in DAU (that is real money); the denominator stays DAU.
-- Payer share    = DAU who bought that day / DAU   (numerator restricted to DAU so it is <= 100%).
with dau as (
    select pd.activity_date, p.platform, pd.player_id
    from pd join player p using (player_id)
    where pd.activity_date between date '2026-01-01' and date '2026-04-30'
),
dau_agg as (
    select activity_date, platform, count(*) as dau from dau group by 1, 2
),
pay as (
    select pu.purchase_date as activity_date, p.platform, pu.player_id,
           sum(pu.usd_amount) as gross
    from pu join player p using (player_id)
    where pu.usd_amount > 0
      and pu.purchase_date between date '2026-01-01' and date '2026-04-30'
    group by 1, 2, 3
),
pay_agg as (
    select pay.activity_date, pay.platform,
           sum(pay.gross) as gross_rev,
           sum(pay.gross) filter (where d.player_id is not null) as gross_rev_from_dau,
           count(*) filter (where d.player_id is not null) as payers_in_dau
    from pay left join dau d
      on d.activity_date = pay.activity_date and d.player_id = pay.player_id
    group by 1, 2
),
refund_agg as (
    select purchase_date as activity_date, p.platform, sum(pu.usd_amount) as refunds
    from pu join player p using (player_id)
    where pu.usd_amount < 0
    group by 1, 2
)
select d.activity_date,
       d.platform,
       d.dau,
       round(coalesce(r.gross_rev, 0), 2)                                      as gross_revenue,
       round(coalesce(f.refunds, 0), 2)                                        as refunds,
       round(coalesce(r.gross_rev, 0) / d.dau, 4)                              as arpdau,
       coalesce(r.payers_in_dau, 0)                                            as payers_in_dau,
       round(coalesce(r.payers_in_dau, 0) * 1.0 / d.dau, 4)                    as payer_share,
       round(coalesce(r.gross_rev, 0) - coalesce(r.gross_rev_from_dau, 0), 2)  as rev_from_non_dau_payers
from dau_agg d
left join pay_agg r on r.activity_date = d.activity_date and r.platform = d.platform
left join refund_agg f on f.activity_date = d.activity_date and f.platform = d.platform
order by d.activity_date, d.platform;
