#!/usr/bin/env bash
# CDP edge: Spark 3 client — CDH parcel often has no spark-sql binary (use spark-class)
# shellcheck disable=SC1091

SPARK_SQL_MAIN_CLASS="${SPARK_SQL_MAIN_CLASS:-org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver}"

# CDP load-spark-env.sh 등은 set -u 셸에서 unset 변수를 참조할 수 있음
_safe_source_spark_file() {
  local f="$1"
  local had_u=0
  case "$-" in *u*) had_u=1; set +u ;; esac
  # load-spark-env.sh (CDH) line ~30
  export SPARK_ENV_LOADED="${SPARK_ENV_LOADED-}"
  # shellcheck disable=SC1090
  source "${f}"
  if [[ "${had_u}" -eq 1 ]]; then set -u; fi
}

_spark_sql_bin_dirs() {
  local d
  if [[ -n "${SPARK_HOME:-}" && -d "${SPARK_HOME}/bin" ]]; then
    printf '%s\n' "${SPARK_HOME}/bin"
  fi
  for d in \
    /opt/cloudera/parcels/spark3/bin \
    /opt/cloudera/parcels/CDH/lib/spark3/bin \
    /opt/cloudera/parcels/SPARK3/bin \
    /opt/cloudera/parcels/SPARK3/lib/spark3/bin; do
    [[ -d "${d}" ]] && printf '%s\n' "${d}"
  done
}

_export_cdh_spark_home() {
  if [[ -n "${SPARK_HOME:-}" && -d "${SPARK_HOME}/bin" ]]; then
    return 0
  fi
  local root
  for root in \
    /opt/cloudera/parcels/spark3 \
    /opt/cloudera/parcels/CDH/lib/spark3 \
    /opt/cloudera/parcels/SPARK3/lib/spark3; do
    if [[ -d "${root}/bin" ]]; then
      export SPARK_HOME="${root}"
      case ":${PATH}:" in
        *":${SPARK_HOME}/bin:"*) ;;
        *) export PATH="${SPARK_HOME}/bin:${PATH}" ;;
      esac
      return 0
    fi
  done
  return 1
}

source_spark_environment() {
  if [[ "${SPARK_ENV_SOURCED:-}" == "1" ]]; then
    return 0
  fi
  if [[ -n "${SPARK_ENV_SCRIPT:-}" && -f "${SPARK_ENV_SCRIPT}" ]]; then
    _safe_source_spark_file "${SPARK_ENV_SCRIPT}"
    export SPARK_ENV_SOURCED=1
    return 0
  fi

  local f
  for f in \
    /opt/cloudera/parcels/CDH/lib/spark3/bin/load-spark-env.sh \
    /opt/cloudera/parcels/spark3/bin/load-spark-env.sh; do
    if [[ -f "${f}" ]]; then
      _safe_source_spark_file "${f}"
      break
    fi
  done

  shopt -s nullglob
  for f in /etc/spark3/conf*/spark-env.sh; do
    if [[ -f "${f}" ]]; then
      _safe_source_spark_file "${f}"
      break
    fi
  done
  shopt -u nullglob 2>/dev/null || true

  for f in \
    /opt/cloudera/parcels/CDH/lib/spark3/bin/spark-config.sh \
    /opt/cloudera/parcels/spark3/bin/spark-config.sh; do
    if [[ -f "${f}" ]]; then
      _safe_source_spark_file "${f}"
      break
    fi
  done

  _export_cdh_spark_home || true
  export SPARK_ENV_SOURCED=1
  return 0
}

_find_spark_sql_in_dir() {
  local dir="$1" name candidate
  for name in spark3-sql spark-sql; do
    candidate="${dir}/${name}"
    if [[ -x "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done
  return 1
}

_spark_class_bin() {
  local bin="${SPARK_HOME:-}/bin/spark-class"
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return 0
  fi
  _export_cdh_spark_home || true
  bin="${SPARK_HOME:-}/bin/spark-class"
  [[ -x "${bin}" ]] && echo "${bin}" && return 0
  return 1
}

# validate / detect: human-readable runner description
resolve_spark_sql_cmd() {
  source_spark_environment

  if [[ -n "${SPARK_SQL_CMD:-}" ]]; then
    if [[ -x "${SPARK_SQL_CMD}" ]] || command -v "${SPARK_SQL_CMD}" >/dev/null 2>&1; then
      echo "${SPARK_SQL_CMD}"
      return 0
    fi
    echo "[ERROR] SPARK_SQL_CMD 를 실행할 수 없음: ${SPARK_SQL_CMD}" >&2
    echo "  (CDH parcel에 spark-sql 이 없으면 SPARK_SQL_CMD 를 비우세요 — spark-class 로 실행)" >&2
    return 1
  fi

  local cmd dir path spark_class
  for cmd in spark3-sql spark-sql; do
    if command -v "${cmd}" >/dev/null 2>&1; then
      command -v "${cmd}"
      return 0
    fi
  done

  while IFS= read -r dir; do
    path="$(_find_spark_sql_in_dir "${dir}")" || continue
    echo "${path}"
    return 0
  done < <(_spark_sql_bin_dirs)

  if spark_class="$(_spark_class_bin 2>/dev/null)"; then
    echo "spark-class:${SPARK_SQL_MAIN_CLASS} (${spark_class})"
    return 0
  fi

  echo "[ERROR] Spark SQL 실행 방법을 찾을 수 없습니다 (spark-sql / spark-class)." >&2
  echo "  진단: ./scripts/detect_spark_client.sh" >&2
  echo "  CDH bin 예: ls /opt/cloudera/parcels/CDH/lib/spark3/bin" >&2
  return 1
}

# Lab SQL 파일 실행 (--conf ... -f file.sql)
exec_spark_sql_file() {
  local file="$1"
  shift
  local sql_args=("$@")

  source_spark_environment

  local runner dir path spark_class
  if [[ -n "${SPARK_SQL_CMD:-}" ]]; then
    if [[ -x "${SPARK_SQL_CMD}" ]] || command -v "${SPARK_SQL_CMD}" >/dev/null 2>&1; then
      exec "${SPARK_SQL_CMD}" "${sql_args[@]}" -f "${file}"
    fi
    echo "[ERROR] SPARK_SQL_CMD 를 실행할 수 없음: ${SPARK_SQL_CMD}" >&2
    exit 1
  fi

  for runner in spark3-sql spark-sql; do
    if command -v "${runner}" >/dev/null 2>&1; then
      exec "$(command -v "${runner}")" "${sql_args[@]}" -f "${file}"
    fi
  done

  while IFS= read -r dir; do
    path="$(_find_spark_sql_in_dir "${dir}")" || continue
    exec "${path}" "${sql_args[@]}" -f "${file}"
  done < <(_spark_sql_bin_dirs)

  spark_class="$(_spark_class_bin)" || {
    echo "[ERROR] ${SPARK_HOME:-SPARK_HOME}/bin/spark-class 없음" >&2
    exit 1
  }
  echo "[INFO] spark-sql 바이너리 없음 → spark-class ${SPARK_SQL_MAIN_CLASS}" >&2
  exec "${spark_class}" "${SPARK_SQL_MAIN_CLASS}" "${sql_args[@]}" -f "${file}"
}
