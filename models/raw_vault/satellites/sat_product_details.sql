{{ config(
    materialized='incremental',
    unique_key=['hk_product', 'load_datetime']
) }}

with stage as (
    select
        hk_product,
        hd_product_details,
        sku,
        name,
        category,
        unit_price,
        active,
        load_datetime,
        record_source
    from {{ ref('stg_products') }}
)

{% if is_incremental() %}
, latest as (
    select hk_product, hd_product_details
    from (
        select
            hk_product,
            hd_product_details,
            row_number() over (partition by hk_product order by load_datetime desc) as rn
        from {{ this }}
    ) ranked
    where rn = 1
)
, changed as (
    select s.*
    from stage s
    left join latest l on s.hk_product = l.hk_product
    where l.hd_product_details is null
       or s.hd_product_details <> l.hd_product_details
)
select * from changed
{% else %}
select * from stage
{% endif %}
