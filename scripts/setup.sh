#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/labs/common/env.sh"
echo "DB ${LAB_DATABASE} — Spark에서 생성 (Lab 01 run.sh 참고)"
echo "warehouse: ${WAREHOUSE}"
