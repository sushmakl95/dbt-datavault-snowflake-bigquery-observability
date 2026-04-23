# BI Export — Tableau / Power BI / Qlik Sense

Superset is the primary BI layer in this repo (zero-cost, OSS). For interview / recruiter questions, here's how the same semantic layer transfers to proprietary tools.

## Tableau (TDS / Hyper)

1. Open Tableau Desktop → `Connect to data` → choose the warehouse (Snowflake/BigQuery/Postgres).
2. Point at the mart schema `marts` and drag `fct_orders_daily`, `dim_customers`, `dim_products`, `dim_date` onto the canvas.
3. Relationships:
   - `fct_orders_daily.ds` ↔ `dim_date.ds`
   - Denormalisation means customer / product attributes are already on the fact for ease.
4. Create calculated fields matching `models/semantic/sales.yml`:
   - `Total GMV` = `SUM([gmv])`
   - `Average Order Value` = `SUM([gmv]) / SUM([orders])`
5. Publish to Tableau Server / Cloud.

## Power BI

1. Use the native Snowflake / BigQuery connector in Power BI Desktop.
2. Import the same tables (prefer DirectQuery for gold mart freshness).
3. Recreate DAX measures from the semantic layer YAML:
   - `Total GMV = SUM(fct_orders_daily[gmv])`
   - `Total Orders = SUM(fct_orders_daily[orders])`
   - `AOV = DIVIDE([Total GMV], [Total Orders])`
4. Use `dim_date` as the date table (mark as date table).

## Qlik Sense

1. Create a new app, add a data connection to the warehouse.
2. Load script (adjust dialect per warehouse):

```qliksense
LOAD ds, country, currency, orders, gmv, unique_products, units
FROM [gold.fct_orders_daily];

LOAD hk_customer, customer_id, full_name, country AS customer_country, tier
FROM [marts.dim_customers];
```

3. Create master measures mirroring the dbt semantic layer.

## Export / automation

The Superset dashboard JSON (`superset/dashboards/sales_vault.json`) exposes chart-level metric definitions. A small Python adapter can translate these into `.tds` (Tableau), `.bim` (Power BI) or `.qvf` (Qlik) at build time — tracked in `scripts/bi_export.py` (future work).
