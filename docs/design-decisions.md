# ADRs

## ADR-001 — Hand-rolled Data Vault macros (no package dependency)
**Status:** Accepted
**Context:** The common DV packages (`automate_dv`, `datavault4dbt`) don't support DuckDB, and CI must be zero-auth.
**Decision:** Implement `hash_key` and `hash_diff` macros in ~30 lines each. Portable across DuckDB, Postgres, Snowflake, BigQuery (all support `md5`).
**Consequences:** Slightly less batteries-included (no automated PIT/bridge generators), but full visibility of the pattern and zero coupling to a package.

## ADR-002 — DuckDB for CI, multi-adapter profiles for env parity
**Status:** Accepted
**Context:** Cloud credentials in CI are a liability; Snowflake trials expire; BigQuery sandbox needs a service account.
**Decision:** `profiles.yml` defines four targets — `ci (duckdb)`, `dev (postgres)`, `stage (bigquery)`, `prod (snowflake)`. CI uses `--target ci`. Dev/stage/prod configs are committed verbatim for portfolio / interview review.
**Consequences:** The models must stay dialect-portable. `dim_date` uses a Jinja branch for BQ's `generate_date_array` vs. the `generate_series` path used by DuckDB/Postgres/Snowflake.

## ADR-003 — Triple orchestration (Airflow + Step Functions + Control-M sim)
**Status:** Accepted
**Context:** Portfolio must demonstrate orchestrator breadth.
**Decision:** Ship parity implementations in `airflow/dags/`, `step_functions/*.asl.json`, and `control_m/jobs/*.json` + `simulator.sh`.
**Consequences:** More surface area but demonstrates the ability to translate the same pipeline across engines — a skill most interviews probe.

## ADR-004 — Incremental hubs/links/satellites from day one
**Status:** Accepted
**Context:** `materialized: table` hides the interesting DV load semantics; `incremental` is how this runs in prod.
**Decision:** Hubs and links use `insert-where-not-exists`; satellites use `hash_diff`-based change detection inside an `is_incremental()` block.
**Consequences:** Slightly more SQL per model, but CI exercises both the initial build and hypothetical incremental branch via model tests.

## ADR-005 — dbt-expectations + native dbt unit tests, no elementary-data in CI
**Status:** Accepted
**Context:** elementary-data requires persisting run artifacts; setting that up in CI adds flakiness.
**Decision:** Use `dbt-expectations` for column-level DQ and native dbt 1.8 `unit_tests:` YAML for logic assertions. Keep elementary integration documented in `docs/observability.md` and wired into docker-compose for local use.
**Consequences:** CI stays hermetic; observability is still a first-class citizen in the platform story.

## ADR-006 — Apache Superset as BI substrate
**Status:** Accepted
**Context:** Tableau/PowerBI/Qlik require paid licenses.
**Decision:** Superset dashboards + YAML datasets. Export notes in `docs/bi-export.md` map measures 1:1 to Tableau/PowerBI/Qlik equivalents.
**Consequences:** Zero-cost BI with a clear migration path.
