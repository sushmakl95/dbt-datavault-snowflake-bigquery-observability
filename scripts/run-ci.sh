#!/usr/bin/env bash
set -euo pipefail

export DBT_PROFILES_DIR="$(pwd)/profiles"

echo "::group::lint"
ruff check spark scripts airflow
yamllint .
python -c "import json,glob; [json.load(open(f)) for f in glob.glob('step_functions/*.asl.json')]"
python -c "import json,glob; [json.load(open(f)) for f in glob.glob('control_m/jobs/*.json')]"
python -m py_compile airflow/dags/dbt_datavault.py airflow/dags/dbt_refresh_marts.py
echo "::endgroup::"

echo "::group::dbt"
dbt deps
dbt seed --target ci --full-refresh
dbt run  --target ci
dbt test --target ci
echo "::endgroup::"
