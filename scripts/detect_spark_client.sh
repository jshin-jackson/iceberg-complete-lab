#!/usr/bin/env bash
# Spark 3 client 진단 (edge에서 실행)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/labs/common/spark_sql_env.sh"

echo "== PATH (spark 관련) =="
echo "${PATH}" | tr ':' '\n' | grep -E 'spark|Spark' || echo "(spark 경로 없음)"

echo ""
echo "== SPARK_HOME =="
echo "${SPARK_HOME:-(unset)}"

echo ""
echo "== source_spark_environment =="
source_spark_environment
echo "SPARK_HOME=${SPARK_HOME:-(unset)}"

echo ""
echo "== which =="
for cmd in spark3-sql spark-sql spark-class spark-submit; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    echo "${cmd} -> $(command -v "${cmd}")"
  else
    echo "${cmd} -> (not found)"
  fi
done

echo ""
echo "== parcel bin 디렉터리 =="
while IFS= read -r dir; do
  echo "--- ${dir} ---"
  if [[ -d "${dir}" ]]; then
    ls -la "${dir}" 2>/dev/null | head -25
  else
    echo "(디렉터리 없음)"
  fi
done < <(_spark_sql_bin_dirs 2>/dev/null || true)

echo ""
echo "== load-spark-env.sh =="
for f in \
  /opt/cloudera/parcels/CDH/lib/spark3/bin/load-spark-env.sh \
  /opt/cloudera/parcels/spark3/bin/load-spark-env.sh; do
  [[ -f "${f}" ]] && echo "found: ${f}"
done

echo ""
echo "== /etc/spark3/conf* =="
ls -d /etc/spark3/conf* 2>/dev/null || echo "(없음)"

echo ""
if SPARK_SQL="$(resolve_spark_sql_cmd 2>/dev/null)"; then
  echo "resolve_spark_sql_cmd OK: ${SPARK_SQL}"
  if [[ "${SPARK_SQL}" != spark-class:* ]]; then
    "${SPARK_SQL}" --version 2>&1 | head -3 || true
  elif sc="$(_spark_class_bin 2>/dev/null)"; then
    "${sc}" "${SPARK_SQL_MAIN_CLASS}" --version 2>&1 | head -3 || true
  fi
else
  echo "resolve_spark_sql_cmd FAILED"
fi

echo ""
echo "Lab 실행: run_spark_sql.sh → spark-sql 없으면 spark-class ${SPARK_SQL_MAIN_CLASS}"
