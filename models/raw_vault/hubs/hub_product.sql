{{ config(materialized='incremental', unique_key='hk_product') }}

with stage as (
    select
        hk_product,
        product_id,
        min(load_datetime) as load_datetime,
        max(record_source)  as record_source
    from {{ ref('stg_products') }}
    group by hk_product, product_id
)

select *
from stage

{% if is_incremental() %}
where hk_product not in (select hk_product from {{ this }})
{% endif %}
