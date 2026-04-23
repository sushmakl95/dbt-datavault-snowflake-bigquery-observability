# Architecture — Sequence & State Diagrams

## 1. dbt run lifecycle (end-to-end)

```mermaid
sequenceDiagram
    autonumber
    actor Sched as Airflow / Step Functions / Control-M
    participant DBT as dbt Core 1.8
    participant PKG as dbt packages
    participant WH as Warehouse<br/>(Snowflake / BQ / DuckDB)
    participant EL as elementary-data
    participant DOCS as dbt docs host
    participant SUP as Superset / Tableau

    Sched->>DBT: dbt deps
    DBT->>PKG: fetch dbt_utils, dbt_expectations
    PKG-->>DBT: installed
    Sched->>DBT: dbt seed --target prod
    DBT->>WH: COPY INTO raw.seed_raw_customers (+orders, +products, +lines)
    Sched->>DBT: dbt run --select tag:hub
    DBT->>WH: INSERT ... hub_customer / hub_order / hub_product<br/>WHERE hk not in this
    Sched->>DBT: dbt run --select tag:link
    DBT->>WH: INSERT ... link_order_customer / link_order_product
    Sched->>DBT: dbt run --select tag:satellite
    DBT->>WH: MERGE satellites using hash_diff change detection
    Sched->>DBT: dbt run --select business_vault.*
    DBT->>WH: CREATE TABLE pit_customer / bridge_order_lines
    Sched->>DBT: dbt run --select marts.*
    DBT->>WH: CREATE TABLE fct_orders_daily, dim_*
    Sched->>DBT: dbt test
    DBT->>WH: execute generic + singular + expectations + unit tests
    DBT->>EL: emit run_results.json + artifacts
    EL->>WH: persist elementary.dbt_* tables
    Sched->>DBT: dbt docs generate
    DBT->>DOCS: upload target/index.html
    SUP->>WH: refresh fct_orders_daily / dim_* datasets
```

---

## 2. Data Vault load sequence (single batch)

```mermaid
sequenceDiagram
    autonumber
    participant Src as Source (OLTP Postgres)
    participant Stg as Staging view
    participant Hub as Hubs (hub_*)
    participant Sat as Satellites (sat_*)
    participant Lnk as Links (link_*)
    participant PIT as PIT (pit_customer)
    participant Brg as Bridge (bridge_order_lines)
    participant Mart as fct_orders_daily

    Src->>Stg: seed_raw_* rows projected
    Stg->>Stg: compute hk_customer = md5(customer_id)<br/>hd_* = md5(desc cols)
    par load hubs
        Stg->>Hub: insert hk_customer if new
        Stg->>Hub: insert hk_order, hk_product if new
    and load links
        Stg->>Lnk: insert hk_link_order_customer, hk_link_order_product
    and load satellites (change-aware)
        Stg->>Sat: if hd_diff != last hd_diff, insert new sat row
    end
    Hub->>PIT: build PIT with latest sat
    Lnk->>Brg: build bridge joining order sat + product sat
    Brg->>Mart: aggregate into daily fact
```

---

## 3. Triple-orchestrator comparison

```mermaid
flowchart LR
    subgraph Airflow["🪂 Airflow DAG"]
        AF1[start]
        AF2[dbt_deps]
        AF3[seed]
        AF4[hubs]
        AF5[links]
        AF6[satellites]
        AF7[biz vault]
        AF8[marts]
        AF9[test]
        AF1-->AF2-->AF3-->AF4-->AF5-->AF6-->AF7-->AF8-->AF9
    end

    subgraph StepFunctions["☁️ AWS Step Functions"]
        SF1[DbtDeps]
        SF2[DbtSeed]
        SF3{Parallel}
        SF4[RunHubs]
        SF5[RunLinks]
        SF6[RunSatellites]
        SF7[RunBusinessVault]
        SF8[RunMarts]
        SF9[DbtTest]
        SF1-->SF2-->SF3
        SF3-->SF4-->SF6
        SF3-->SF5-->SF6
        SF6-->SF7-->SF8-->SF9
    end

    subgraph ControlM["🧭 Control-M Simulator"]
        CM1[dbt_deps]
        CM2[dbt_seed]
        CM3[dbt_hubs]
        CM4[dbt_links]
        CM5[dbt_satellites]
        CM6[dbt_business_vault]
        CM7[dbt_marts]
        CM8[dbt_test]
        CM1-->CM2-->CM3-->CM4-->CM5-->CM6-->CM7-->CM8
    end
```

The same dbt invocations are orchestrated by all three engines. Choose one per environment:
- **Airflow** for cloud-native teams with Python-heavy ecosystems
- **Step Functions** for AWS-native serverless deployments
- **Control-M** for enterprise / regulated environments with existing CTM estate

---

## 4. Test pyramid

```mermaid
flowchart TB
    A[Native dbt unit tests<br/>YAML + given/expect]
    B[Generic tests<br/>not_null, unique, accepted_values,<br/>relationships]
    C[dbt-expectations tests<br/>column min/max, between, regex]
    D[Singular tests<br/>tests/singular/*.sql]
    E[Data contract validation<br/>ODCS v3 manifests]
    F[elementary-data monitors<br/>freshness, volume, schema]

    A-->B-->C-->D-->E-->F
```
