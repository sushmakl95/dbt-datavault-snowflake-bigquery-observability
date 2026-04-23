{{ config(materialized='incremental', unique_key='hk_order') }}

with stage as (
    select
        hk_order,
        order_id,
        min(load_datetime) as load_datetime,
        max(record_source)  as record_source
    from {{ ref('stg_orders') }}
    group by hk_order, order_id
)

select *
from stage

{% if is_incremental() %}
where hk_order not in (select hk_order from {{ this }})
{% endif %}
