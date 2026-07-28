#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
COMMON="../common"
bash "$COMMON/run_spark_sql.sh" sql/spark/01_lab.sql
bash "$COMMON/run_hive_sql.sh" sql/hive/01_lab.sql
bash "$COMMON/run_impala_sql.sh" sql/impala/01_lab.sql
echo "run.sh 완료"
