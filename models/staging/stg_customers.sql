{{ config(materialized='view') }}

with src as (
    select * from {{ ref('seed_raw_customers') }}
)

select
    customer_id,
    lower(trim(email)) as email,
    first_name,
    last_name,
    upper(trim(country)) as country,
    cast(signup_ts as timestamp) as signup_ts,
    lower(trim(tier)) as tier,
    {{ hash_key(['customer_id']) }} as hk_customer,
    {{ hash_diff(['email', 'first_name', 'last_name', 'country', 'tier']) }} as hd_customer_details,
    {{ load_datetime() }} as load_datetime,
    {{ record_source('stg_customers') }} as record_source
from src
