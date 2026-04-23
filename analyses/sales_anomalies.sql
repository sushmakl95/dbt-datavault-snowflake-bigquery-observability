-- Analyses are compiled but not run. This one surfaces day-over-day GMV anomalies
-- against a 7-day rolling baseline. Reproduced as a dbt-expectations anomaly test
-- in models/marts/schema.yml.

with daily as (
    select ds, country, sum(gmv) as gmv
    from {{ ref('fct_orders_daily') }}
    group by ds, country
),

roll as (
    select
        ds,
        country,
        gmv,
        avg(gmv) over (
            partition by country
            order by ds
            rows between 7 preceding and 1 preceding
        ) as avg_7d
    from daily
)

select
    ds,
    country,
    gmv,
    avg_7d,
    case when gmv < 0.5 * avg_7d then 'ANOMALY_LOW'
         when gmv > 2.0 * avg_7d then 'ANOMALY_HIGH'
         else 'OK'
    end as status
from roll
where avg_7d is not null
