{{ config(
    materialized='incremental',
    unique_key=['hk_order', 'load_datetime']
) }}

with stage as (
    select
        hk_order,
        hd_order_details,
        placed_at,
        ds,
        country,
        currency,
        total,
        status,
        load_datetime,
        record_source
    from {{ ref('stg_orders') }}
)

{% if is_incremental() %}
, latest as (
    select hk_order, hd_order_details
    from (
        select
            hk_order,
            hd_order_details,
            row_number() over (partition by hk_order order by load_datetime desc) as rn
        from {{ this }}
    ) ranked
    where rn = 1
)
, changed as (
    select s.*
    from stage s
    left join latest l on s.hk_order = l.hk_order
    where l.hd_order_details is null
       or s.hd_order_details <> l.hd_order_details
)
select * from changed
{% else %}
select * from stage
{% endif %}
