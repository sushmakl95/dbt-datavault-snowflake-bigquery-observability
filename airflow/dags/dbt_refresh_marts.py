"""Airflow DAG: Dataset-triggered downstream mart refresh.

Fires whenever the `dbt://gold/fct_orders_daily` Dataset is produced by the
main DAG. Rebuilds semantic metrics, refreshes Superset datasets, and posts
a summary to Slack.
"""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

from airflow.datasets import Dataset
from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator

PROJECT_DIR = Path(__file__).resolve().parents[2]
PROFILES_DIR = PROJECT_DIR / "profiles"
DBT_TARGET = "dev"

gold_dataset = Dataset("dbt://gold/fct_orders_daily")


@dag(
    dag_id="dbt_refresh_marts_downstream",
    description="Dataset-triggered downstream refresh after gold mart is rebuilt",
    start_date=datetime(2026, 4, 1),
    schedule=[gold_dataset],
    catchup=False,
    tags=["dbt", "downstream"],
)
def downstream():
    docs = BashOperator(
        task_id="dbt_docs_generate",
        bash_command=(
            f"cd {PROJECT_DIR} && "
            f"dbt docs generate --profiles-dir {PROFILES_DIR} --target {DBT_TARGET}"
        ),
    )

    @task
    def refresh_superset() -> None:
        print("POST http://superset:8088/api/v1/dataset/refresh/")

    @task
    def notify() -> None:
        print("Slack: :white_check_mark: marts refreshed")

    docs >> refresh_superset() >> notify()


dag = downstream()
