{{ config(materialized='table') }}

with bridge as (
    select * from {{ ref('bridge_order_lines') }}
),

agg as (
    select
        ds,
        country,
        currency,
        status,
        count(distinct hk_order) as orders,
        sum(line_total)          as gmv,
        count(distinct hk_product) as unique_products,
        sum(qty)                 as units
    from bridge
    group by ds, country, currency, status
)

select
    a.*,
    current_timestamp as computed_at
from agg a
