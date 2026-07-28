#!/usr/bin/env bash
# CDP edge: spark-env 로 PATH 설정, spark3-sql / spark-sql 탐색
# shellcheck disable=SC1091

source_spark_environment() {
  if [[ "${SPARK_ENV_SOURCED:-}" == "1" ]]; then
    return 0
  fi
  if [[ -n "${SPARK_ENV_SCRIPT:-}" && -f "${SPARK_ENV_SCRIPT}" ]]; then
    # shellcheck disable=SC1090
    source "${SPARK_ENV_SCRIPT}"
    export SPARK_ENV_SOURCED=1
    return 0
  fi
  local f
  for f in \
    /etc/spark3/conf.cloudera.spark3_on_yarn/spark-env.sh \
    /etc/spark3/conf.cloudera.spark_on_yarn/spark-env.sh \
    /etc/spark3/conf/spark-env.sh; do
    if [[ -f "${f}" ]]; then
      source "${f}"
      export SPARK_ENV_SOURCED=1
      return 0
    fi
  done
  return 0
}

resolve_spark_sql_cmd() {
  if [[ -n "${SPARK_SQL_CMD:-}" ]]; then
    if [[ -x "${SPARK_SQL_CMD}" ]] || command -v "${SPARK_SQL_CMD}" >/dev/null 2>&1; then
      echo "${SPARK_SQL_CMD}"
      return 0
    fi
    echo "[ERROR] SPARK_SQL_CMD 를 실행할 수 없음: ${SPARK_SQL_CMD}" >&2
    return 1
  fi

  local cmd path
  for cmd in spark3-sql spark-sql; do
    if command -v "${cmd}" >/dev/null 2>&1; then
      echo "${cmd}"
      return 0
    fi
  done
  for path in \
    /opt/cloudera/parcels/SPARK3/bin/spark3-sql \
    /opt/cloudera/parcels/SPARK3/lib/spark3/bin/spark3-sql; do
    if [[ -x "${path}" ]]; then
      echo "${path}"
      return 0
    fi
  done

  echo "[ERROR] spark3-sql / spark-sql 을 찾을 수 없습니다." >&2
  echo "  edge에서 Spark 3 client 설정 후 다시 시도:" >&2
  echo "    source /etc/spark3/conf.cloudera.spark3_on_yarn/spark-env.sh" >&2
  echo "  또는 .env 에 SPARK_SQL_CMD=/opt/cloudera/parcels/SPARK3/bin/spark3-sql" >&2
  return 1
}
