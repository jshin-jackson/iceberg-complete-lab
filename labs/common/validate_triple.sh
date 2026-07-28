#!/usr/bin/env bash
# Lab 디렉터리에서 실행: ../common/validate_triple.sh
set -e
LAB_DIR="$(pwd)"
COMMON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${COMMON}/run_spark_sql.sh" "${LAB_DIR}/validate_spark.sql"
bash "${COMMON}/run_hive_sql.sh" "${LAB_DIR}/validate_hive.sql"
bash "${COMMON}/run_impala_sql.sh" "${LAB_DIR}/validate_impala.sql"
echo "OK: $(basename "${LAB_DIR}") — Spark / Hive / Impala 검증 완료"
