SHELL := bash
PY := python

export DBT_PROFILES_DIR := $(PWD)/profiles

.PHONY: help install lint dbt-deps dbt-ci dbt-docs ci airflow-up compose-up controlm-sim clean

help:
	@echo "install      - install python + dbt deps"
	@echo "lint         - ruff + black + sqlfluff + yamllint"
	@echo "dbt-ci       - dbt deps + seed + run + test on DuckDB"
	@echo "dbt-docs     - dbt docs generate"
	@echo "ci           - full CI pipeline"
	@echo "airflow-up   - run local Airflow (docker-compose)"
	@echo "compose-up   - postgres + superset + elementary"
	@echo "controlm-sim - simulate Control-M job definitions"
	@echo "clean        - remove build artifacts"

install:
	$(PY) -m pip install -U pip
	$(PY) -m pip install -r requirements-dev.txt
	dbt deps

lint:
	ruff check .
	black --check spark scripts airflow || true
	sqlfluff lint models --processes 4
	yamllint .

dbt-deps:
	dbt deps

dbt-ci: dbt-deps
	dbt seed --target ci --full-refresh
	dbt run  --target ci
	dbt test --target ci

dbt-docs:
	dbt docs generate --target ci

ci: lint dbt-ci

airflow-up:
	docker compose --profile airflow up -d

compose-up:
	docker compose up -d postgres superset

controlm-sim:
	bash control_m/simulator.sh

clean:
	rm -rf target dbt_packages logs .pytest_cache .ruff_cache *.duckdb *.duckdb.wal
	find . -type d -name __pycache__ -exec rm -rf {} +
