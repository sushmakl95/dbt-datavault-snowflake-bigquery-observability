-- Singular test: ensure no non-cancelled order has zero or negative total.

select order_id, total, status
from {{ ref('stg_orders') }}
where status <> 'CANCELLED'
  and total <= 0
