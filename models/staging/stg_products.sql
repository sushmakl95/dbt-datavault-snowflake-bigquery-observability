{{ config(materialized='view') }}

with src as (
    select * from {{ ref('seed_raw_products') }}
)

select
    product_id,
    upper(trim(sku)) as sku,
    name,
    lower(trim(category)) as category,
    cast(unit_price as decimal(18, 2)) as unit_price,
    cast(active as boolean) as active,
    {{ hash_key(['product_id']) }} as hk_product,
    {{ hash_diff(['sku', 'name', 'category', 'unit_price', 'active']) }} as hd_product_details,
    {{ load_datetime() }} as load_datetime,
    {{ record_source('stg_products') }} as record_source
from src
