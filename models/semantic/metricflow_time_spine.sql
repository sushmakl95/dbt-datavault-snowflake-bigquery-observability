{{ config(materialized='table') }}

-- Required by dbt's semantic layer. Dense daily time spine, 2024-01-01 .. 2028-12-31.
-- Adapters: DuckDB / Postgres use generate_series; BigQuery branches to generate_date_array.

{% if target.type == 'bigquery' %}

select d as date_day
from unnest(generate_date_array(date '2024-01-01', date '2028-12-31')) d

{% else %}

with span as (
    select cast('2024-01-01' as date) as start_date,
           cast('2028-12-31' as date) as end_date
),
days as (
    select cast(start_date + interval (i) day as date) as date_day
    from span, generate_series(
        0,
        cast(end_date as date) - cast(start_date as date),
        1
    ) as gs(i)
)
select date_day from days

{% endif %}
