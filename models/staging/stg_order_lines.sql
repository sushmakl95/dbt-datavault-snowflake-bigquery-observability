{{ config(materialized='view') }}

with src as (
    select * from {{ ref('seed_raw_order_lines') }}
)

select
    order_id,
    product_id,
    cast(qty as integer) as qty,
    cast(unit_price as decimal(18, 2)) as unit_price,
    cast(qty as decimal(18, 2)) * cast(unit_price as decimal(18, 2)) as line_total,
    {{ hash_key(['order_id', 'product_id']) }} as hk_link_order_product,
    {{ hash_key(['order_id']) }} as hk_order,
    {{ hash_key(['product_id']) }} as hk_product,
    {{ load_datetime() }} as load_datetime,
    {{ record_source('stg_order_lines') }} as record_source
from src
