{{ config(materialized='view') }}

with src as (
    select * from {{ ref('seed_raw_orders') }}
)

select
    order_id,
    customer_id,
    cast(placed_at as timestamp) as placed_at,
    cast(placed_at as date) as ds,
    upper(trim(country)) as country,
    upper(trim(currency)) as currency,
    cast(total as decimal(18, 2)) as total,
    upper(trim(status)) as status,
    {{ hash_key(['order_id']) }} as hk_order,
    {{ hash_key(['customer_id']) }} as hk_customer,
    {{ hash_key(['order_id', 'customer_id']) }} as hk_link_order_customer,
    {{ hash_diff(['status', 'total', 'currency', 'country']) }} as hd_order_details,
    {{ load_datetime() }} as load_datetime,
    {{ record_source('stg_orders') }} as record_source
from src
