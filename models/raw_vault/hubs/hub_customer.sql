{{ config(materialized='incremental', unique_key='hk_customer') }}

with stage as (
    select
        hk_customer,
        customer_id,
        min(load_datetime) as load_datetime,
        max(record_source)  as record_source
    from {{ ref('stg_customers') }}
    group by hk_customer, customer_id
)

select *
from stage

{% if is_incremental() %}
where hk_customer not in (select hk_customer from {{ this }})
{% endif %}
