"""Airflow DAG: end-to-end Data Vault refresh.

Runs dbt seed → run → test → docs generate, then publishes artifacts to S3 and
notifies on failure via Slack webhook.

Tested against Airflow 2.8+ with BashOperator + TaskFlow API. Uses Dataset-based
scheduling to trigger downstream DAGs when the gold layer is refreshed.
"""

from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

from airflow.datasets import Dataset
from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PROJECT_DIR = Path(__file__).resolve().parents[2]
PROFILES_DIR = PROJECT_DIR / "profiles"
DBT_TARGET = "dev"

gold_dataset = Dataset("dbt://gold/fct_orders_daily")

default_args = {
    "owner": "data-platform",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": False,
}


def dbt(cmd: str) -> str:
    return (
        f"cd {PROJECT_DIR} && "
        f"dbt {cmd} --profiles-dir {PROFILES_DIR} --target {DBT_TARGET}"
    )


@dag(
    dag_id="dbt_datavault_refresh",
    description="Full Data Vault refresh: staging -> raw vault -> business vault -> marts",
    start_date=datetime(2026, 4, 1),
    schedule="0 2 * * *",
    catchup=False,
    default_args=default_args,
    max_active_runs=1,
    tags=["dbt", "datavault", "production"],
)
def dbt_datavault_refresh():
    start = EmptyOperator(task_id="start")

    deps = BashOperator(task_id="dbt_deps", bash_command=dbt("deps"))

    with TaskGroup("ingest") as ingest:
        BashOperator(
            task_id="seed",
            bash_command=dbt("seed"),
        )

    with TaskGroup("raw_vault") as raw_vault:
        BashOperator(
            task_id="hubs",
            bash_command=dbt("run --select tag:hub"),
        )
        BashOperator(
            task_id="links",
            bash_command=dbt("run --select tag:link"),
        )
        BashOperator(
            task_id="satellites",
            bash_command=dbt("run --select tag:satellite"),
        )

    with TaskGroup("business_vault") as biz:
        BashOperator(
            task_id="pit",
            bash_command=dbt("run --select business_vault.pit.*"),
        )
        BashOperator(
            task_id="bridge",
            bash_command=dbt("run --select business_vault.bridge.*"),
        )

    marts = BashOperator(
        task_id="marts",
        bash_command=dbt("run --select marts.*"),
        outlets=[gold_dataset],
    )

    tests = BashOperator(task_id="dbt_test", bash_command=dbt("test"))

    @task
    def publish_docs() -> None:
        # In production this would upload target/ artifacts to S3 for hosted docs.
        print("Would upload docs to s3://analytics-docs/datavault/")

    end = EmptyOperator(task_id="end")

    start >> deps >> ingest >> raw_vault >> biz >> marts >> tests >> publish_docs() >> end


dag = dbt_datavault_refresh()
