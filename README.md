# dbt-datavault-snowflake-bigquery-observability

Production-grade **Data Vault 2.0** analytics platform on **dbt** with **multi-adapter** support (Snowflake, BigQuery, and DuckDB for hermetic CI), orchestrated by three parallel schedulers (**Airflow**, **AWS Step Functions**, and a **Control-M simulator**), with **elementary-data** observability, **dbt-expectations** data quality, a **PySpark seed generator**, and an **Apache Superset** BI layer.

CI runs `dbt seed → run → test → docs generate` against **DuckDB** — no cloud credentials, zero dollar cost, green on first push.

![CI](https://github.com/sushmakl95/dbt-datavault-snowflake-bigquery-observability/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![dbt](https://img.shields.io/badge/dbt-1.8+-orange)

---

## Architecture

```mermaid
flowchart LR
    subgraph Sources["📥 Sources"]
        ORD[(OLTP Postgres<br/>orders)]
        CRM[(CRM API<br/>customers)]
        PROD[(Product catalog<br/>CSV drops)]
    end

    subgraph Ingest["🌀 Ingest"]
        SPK[PySpark seed<br/>generator]
        STG[dbt staging<br/>stg_*]
    end

    subgraph RawVault["🟫 Raw Vault"]
        HUB[Hubs<br/>hub_customer<br/>hub_order<br/>hub_product]
        LNK[Links<br/>link_order_customer<br/>link_order_product]
        SAT[Satellites<br/>sat_customer_details<br/>sat_order_details<br/>sat_product_details]
    end

    subgraph BizVault["🟪 Business Vault"]
        PIT[PIT tables<br/>pit_customer]
        BRG[Bridge tables<br/>bridge_order_lines]
    end

    subgraph Marts["🟧 Marts"]
        FCT[fct_orders_daily]
        DIM[dim_customers<br/>dim_products<br/>dim_date]
        SEM[Semantic Layer<br/>MetricFlow]
    end

    subgraph DQ["✅ DQ + Observability"]
        GE[dbt-expectations]
        UT[Native unit tests]
        EL[elementary-data]
        OD[Open Data Contract<br/>Standard v3]
    end

    subgraph Orch["🎯 Orchestration (triple)"]
        AF[Airflow DAG<br/>dbt_datavault]
        SF[Step Functions<br/>dbt_run_pipeline]
        CM[Control-M simulator<br/>+ job JSON]
    end

    subgraph BI["📊 Consume"]
        SUP[Apache Superset]
        TB[[Tableau / PowerBI / Qlik<br/>export spec]]
    end

    ORD --> SPK --> STG
    CRM --> STG
    PROD --> SPK
    STG --> HUB
    STG --> LNK
    STG --> SAT
    HUB --> PIT
    SAT --> PIT
    LNK --> BRG
    PIT --> FCT
    BRG --> FCT
    HUB --> DIM
    SAT --> DIM
    FCT --> SEM
    DIM --> SEM
    SEM --> SUP
    SEM --> TB

    GE -. tests .-> RawVault
    GE -. tests .-> Marts
    UT -. tests .-> Marts
    EL -. monitors .-> Marts
    OD -. contracts .-> Sources

    AF -. triggers .-> STG
    SF -. triggers .-> STG
    CM -. triggers .-> STG
```

See [`docs/architecture.md`](docs/architecture.md) for full sequence diagrams (dbt run lifecycle, DV load sequence, and orchestrator comparison).

---

## Tech highlights

| Layer | Technologies |
|---|---|
| **Modeling** | **Data Vault 2.0** (hand-rolled macros, adapter-agnostic): hubs, links, satellites, PIT, bridge |
| **Transformation** | dbt Core 1.8 (unit tests, contracts, versions, exposures, semantic layer) |
| **Warehouses** | Snowflake (prod), BigQuery sandbox (stage), **DuckDB** (CI), Postgres (dev) |
| **Data Quality** | dbt-expectations, dbt_utils tests, native dbt unit tests, custom generic tests |
| **Observability** | elementary-data integration, dbt artifacts upload, source freshness, OpenLineage emitter |
| **Contracts** | Open Data Contract Standard (ODCS v3) for every source |
| **Orchestration** | Airflow 2.8 DAG, Step Functions ASL, Control-M simulator (bash + authentic JSON job defs) |
| **Ingestion** | PySpark seed generator producing realistic multi-table fixtures |
| **BI** | Superset dashboards (Tableau/PowerBI/Qlik exportable) |
| **CI/CD** | GitHub Actions (dbt build + sqlfluff + python lint), Jenkinsfile, GitLab mirror |

---

## Quickstart

```bash
make install
make lint           # ruff + sqlfluff + yamllint
make dbt-ci         # dbt deps + seed + run + test on DuckDB (no creds)
make docs           # dbt docs generate + serve
make compose-up     # Postgres + Superset + elementary UI
make airflow-up     # local Airflow for DAG demo
make controlm-sim   # simulate Control-M job definitions
```

---

## Project layout

```
dbt-datavault-snowflake-bigquery-observability/
├── .github/workflows/ci.yml
├── Makefile, Jenkinsfile, .gitlab-ci.yml
├── dbt_project.yml, packages.yml, profiles/profiles.yml
├── docs/                    # architecture, design decisions, DV guide, BI export notes
├── airflow/dags/            # dbt_datavault, dbt_refresh_marts
├── step_functions/          # ASL state machines
├── control_m/               # authentic job JSON + bash simulator
├── models/
│   ├── staging/             # stg_orders, stg_customers, stg_products
│   ├── raw_vault/           # hubs/, links/, satellites/
│   ├── business_vault/      # pit/, bridge/
│   ├── marts/               # fct_* + dim_* + dim_date
│   └── semantic/            # MetricFlow YAML (sales, customers)
├── macros/                  # hash_key, hash_diff, generate_schema_name
├── seeds/                   # CSV seeds used by DuckDB CI + Snowflake/BQ dev
├── snapshots/               # SCD2 snapshot definitions
├── tests/                   # generic + singular + unit (native dbt 1.8 YAML)
├── analyses/                # ad-hoc analyses for documentation
├── exposures/               # downstream consumers (Superset, Tableau)
├── spark/                   # PySpark seed generator
├── superset/                # dashboards + datasets
└── scripts/                 # helpers
```

---

## Zero-cost posture

| Production warehouse | Local substitute | Prod config? |
|---|---|---|
| Snowflake | dbt-duckdb in CI | `profiles/profiles.yml` includes snowflake target, with prod docs |
| BigQuery | dbt-duckdb in CI | same — bigquery target documented, sandbox-compatible |
| Redshift | Postgres / DuckDB | compatibility notes in `docs/warehouses.md` |

---

## License

MIT.
