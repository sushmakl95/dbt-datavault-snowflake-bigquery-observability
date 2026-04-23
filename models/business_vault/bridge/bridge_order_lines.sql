{{ config(materialized='table') }}

-- Bridge: flattened order-line view combining the order hub, product hub,
-- and descriptive attributes from satellites. Intended as a performance-oriented
-- denormalised structure between Raw Vault and Marts.

with link as (
    select hk_link_order_product, hk_order, hk_product
    from {{ ref('link_order_product') }}
),

order_desc as (
    select * from (
        select
            hk_order, placed_at, ds, country, currency, total, status, load_datetime,
            row_number() over (partition by hk_order order by load_datetime desc) as rn
        from {{ ref('sat_order_details') }}
    ) r
    where rn = 1
),

product_desc as (
    select * from (
        select
            hk_product, sku, name, category, unit_price, active, load_datetime,
            row_number() over (partition by hk_product order by load_datetime desc) as rn
        from {{ ref('sat_product_details') }}
    ) r
    where rn = 1
),

lines as (
    select hk_link_order_product, qty, unit_price as line_unit_price, line_total
    from {{ ref('stg_order_lines') }}
)

select
    l.hk_link_order_product,
    l.hk_order,
    l.hk_product,
    od.placed_at,
    od.ds,
    od.country,
    od.currency,
    od.status,
    pd.sku,
    pd.name as product_name,
    pd.category,
    ln.qty,
    ln.line_unit_price,
    ln.line_total
from link l
left join order_desc   od using (hk_order)
left join product_desc pd using (hk_product)
left join lines        ln using (hk_link_order_product)
