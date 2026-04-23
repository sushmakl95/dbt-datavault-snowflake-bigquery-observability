{{ config(materialized='incremental', unique_key='hk_link_order_customer') }}

with stage as (
    select
        hk_link_order_customer,
        hk_order,
        hk_customer,
        min(load_datetime) as load_datetime,
        max(record_source)  as record_source
    from {{ ref('stg_orders') }}
    group by hk_link_order_customer, hk_order, hk_customer
)

select *
from stage

{% if is_incremental() %}
where hk_link_order_customer not in (select hk_link_order_customer from {{ this }})
{% endif %}
