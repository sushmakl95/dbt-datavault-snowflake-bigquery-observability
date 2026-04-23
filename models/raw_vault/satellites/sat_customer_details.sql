{{ config(
    materialized='incremental',
    unique_key=['hk_customer', 'load_datetime']
) }}

with stage as (
    select
        hk_customer,
        hd_customer_details,
        email,
        first_name,
        last_name,
        country,
        tier,
        load_datetime,
        record_source
    from {{ ref('stg_customers') }}
)

{% if is_incremental() %}
, latest as (
    select hk_customer, hd_customer_details
    from (
        select
            hk_customer,
            hd_customer_details,
            row_number() over (partition by hk_customer order by load_datetime desc) as rn
        from {{ this }}
    ) ranked
    where rn = 1
)
, changed as (
    select s.*
    from stage s
    left join latest l on s.hk_customer = l.hk_customer
    where l.hd_customer_details is null
       or s.hd_customer_details <> l.hd_customer_details
)
select * from changed
{% else %}
select * from stage
{% endif %}
