#!/usr/bin/env bash
# Control-M simulator: reads the job JSON files and executes the Flow sequence
# locally, printing Control-M-style job state transitions. Mirrors the semantics
# of Control-M Automation API enough to demo the job flow without a real CTM server.

set -euo pipefail

JOB_FILE="${1:-control_m/jobs/dbt_datavault_job.json}"
FOLDER="${2:-DV_DAILY}"

if ! command -v jq >/dev/null; then
  echo "[ctm-sim] jq is required (https://stedolan.github.io/jq/)"; exit 1
fi

echo "[ctm-sim] loading folder $FOLDER from $JOB_FILE"

SEQ=$(jq -r ".\"$FOLDER\".Flow.Sequence[]" "$JOB_FILE")

for job in $SEQ; do
  cmd=$(jq -r ".\"$FOLDER\".\"$job\".Command // empty" "$JOB_FILE")
  if [[ -z "$cmd" ]]; then
    echo "[ctm-sim] $job: NO COMMAND (non-Command job type)"
    continue
  fi
  echo "[ctm-sim] [OH-Wait] $job ...."
  echo "[ctm-sim] [Executing] $job: $cmd"
  # In a real run the command would execute here. For the demo, we just log it.
  # eval "$cmd"
  echo "[ctm-sim] [Ended OK] $job"
done

echo "[ctm-sim] folder $FOLDER complete"
