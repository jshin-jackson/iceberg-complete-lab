#!/usr/bin/env bash
# Spark SQL 파일 실행
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/env.sh"
FILE="${1:?usage: run_spark_sql.sh file.sql}"
spark3-sql \
  --conf "spark.sql.catalog.${ICEBERG_CATALOG}=org.apache.iceberg.spark.SparkCatalog" \
  --conf "spark.sql.catalog.${ICEBERG_CATALOG}.type=hive" \
  --conf "spark.sql.catalog.${ICEBERG_CATALOG}.warehouse=${WAREHOUSE}" \
  --conf "spark.kerberos.principal=${SPARK_YARN_PRINCIPAL:-${KERBEROS_PRINCIPAL}}" \
  --conf "spark.kerberos.keytab=${SPARK_YARN_KEYTAB:-${KERBEROS_KEYTAB}}" \
  -f "${FILE}"
