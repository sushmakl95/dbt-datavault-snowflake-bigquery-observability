{{ config(materialized='table') }}

-- Compact date dimension generated from the orders span. Duckdb / Snowflake /
-- BigQuery all support generate_series / unnest(generate_date_array).

{% if target.type == 'bigquery' %}

select
    d as ds,
    extract(year from d) as year,
    extract(month from d) as month,
    extract(day from d) as day,
    extract(dayofweek from d) as day_of_week,
    format_date('%A', d) as day_name,
    format_date('%B', d) as month_name
from unnest(generate_date_array(date '2024-01-01', date '2027-12-31')) d

{% else %}

with span as (
    select cast('2024-01-01' as date) as start_date,
           cast('2027-12-31' as date) as end_date
),

days as (
    select cast(start_date + interval (i) day as date) as ds
    from span, generate_series(
        0,
        cast(end_date as date) - cast(start_date as date),
        1
    ) as gs(i)
)

select
    ds,
    extract(year from ds)   as year,
    extract(month from ds)  as month,
    extract(day from ds)    as day,
    extract(dow from ds)    as day_of_week,
    strftime(ds, '%A')      as day_name,
    strftime(ds, '%B')      as month_name
from days

{% endif %}
