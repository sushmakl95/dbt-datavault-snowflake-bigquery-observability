{% snapshot snapshot_customers %}
{{
    config(
      target_schema='snapshots',
      strategy='check',
      unique_key='customer_id',
      check_cols=['email', 'country', 'tier']
    )
}}

select
    customer_id,
    email,
    first_name,
    last_name,
    country,
    tier,
    signup_ts
from {{ ref('seed_raw_customers') }}

{% endsnapshot %}
