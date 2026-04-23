-- Assert every link row points to existing hub rows (belt-and-braces over relationships tests).

with orphan_customers as (
    select l.hk_customer
    from {{ ref('link_order_customer') }} l
    left join {{ ref('hub_customer') }} h using (hk_customer)
    where h.hk_customer is null
),
orphan_orders as (
    select l.hk_order
    from {{ ref('link_order_customer') }} l
    left join {{ ref('hub_order') }} h using (hk_order)
    where h.hk_order is null
)
,
violations as (
    select 'orphan_customer' as violation, count(*) as bad_rows from orphan_customers
    union all
    select 'orphan_order' as violation, count(*) as bad_rows from orphan_orders
)
select * from violations where bad_rows > 0
