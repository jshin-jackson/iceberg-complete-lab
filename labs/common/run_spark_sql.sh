#!/usr/bin/env bash
# Spark SQL 파일 실행 (CDP Spark 3 + Iceberg)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/env.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/spark_sql_env.sh"

FILE="${1:?usage: run_spark_sql.sh file.sql}"

source_spark_environment
SPARK_SQL="$(resolve_spark_sql_cmd)"

MASTER="${SPARK_MASTER:-yarn}"
EXTRA=()
if [[ -n "${MASTER}" ]]; then
  EXTRA=(--master "${MASTER}")
fi

exec "${SPARK_SQL}" "${EXTRA[@]}" \
  --conf "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions" \
  --conf "spark.sql.catalog.${ICEBERG_CATALOG}=org.apache.iceberg.spark.SparkCatalog" \
  --conf "spark.sql.catalog.${ICEBERG_CATALOG}.type=hive" \
  --conf "spark.sql.catalog.${ICEBERG_CATALOG}.warehouse=${WAREHOUSE}" \
  --conf "spark.hadoop.hive.metastore.uris=${HMS_URI}" \
  --conf "spark.kerberos.principal=${SPARK_YARN_PRINCIPAL:-${KERBEROS_PRINCIPAL}}" \
  --conf "spark.kerberos.keytab=${SPARK_YARN_KEYTAB:-${KERBEROS_KEYTAB}}" \
  -f "${FILE}"
