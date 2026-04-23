{{ config(materialized='table') }}

-- Point-in-Time (PIT) table for the Customer hub. Joins to the latest satellite
-- record per hub key at the as_of snapshot date (here: today).

with hub as (
    select hk_customer, customer_id
    from {{ ref('hub_customer') }}
),

sat_latest as (
    select * from (
        select
            hk_customer,
            hd_customer_details,
            email,
            first_name,
            last_name,
            country,
            tier,
            load_datetime,
            row_number() over (partition by hk_customer order by load_datetime desc) as rn
        from {{ ref('sat_customer_details') }}
    ) ranked
    where rn = 1
)

select
    h.hk_customer,
    h.customer_id,
    s.email,
    s.first_name,
    s.last_name,
    s.country,
    s.tier,
    s.load_datetime as sat_load_datetime,
    current_timestamp as as_of_timestamp
from hub h
left join sat_latest s using (hk_customer)
