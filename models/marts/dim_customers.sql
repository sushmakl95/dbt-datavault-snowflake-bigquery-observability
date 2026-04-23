{{ config(materialized='table') }}

select
    hk_customer,
    customer_id,
    email,
    first_name || ' ' || last_name as full_name,
    country,
    tier,
    sat_load_datetime as last_updated_at
from {{ ref('pit_customer') }}
