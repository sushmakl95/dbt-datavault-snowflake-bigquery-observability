{{ config(materialized='incremental', unique_key='hk_link_order_product') }}

with stage as (
    select
        hk_link_order_product,
        hk_order,
        hk_product,
        min(load_datetime) as load_datetime,
        max(record_source)  as record_source
    from {{ ref('stg_order_lines') }}
    group by hk_link_order_product, hk_order, hk_product
)

select *
from stage

{% if is_incremental() %}
where hk_link_order_product not in (select hk_link_order_product from {{ this }})
{% endif %}
