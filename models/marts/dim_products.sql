{{ config(materialized='table') }}

with latest as (
    select * from (
        select
            hk_product, sku, name, category, unit_price, active, load_datetime,
            row_number() over (partition by hk_product order by load_datetime desc) as rn
        from {{ ref('sat_product_details') }}
    ) r
    where rn = 1
)

select
    h.hk_product,
    h.product_id,
    l.sku,
    l.name as product_name,
    l.category,
    l.unit_price,
    l.active
from {{ ref('hub_product') }} h
left join latest l using (hk_product)
