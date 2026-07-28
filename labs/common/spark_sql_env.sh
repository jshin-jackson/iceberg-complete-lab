#!/usr/bin/env bash
# CDP edge: Spark 3 client — spark-sql 없으면 spark-submit (+ PySpark fallback)
# shellcheck disable=SC1091

SPARK_SQL_MAIN_CLASS="${SPARK_SQL_MAIN_CLASS:-org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver}"
SPARK_SQL_RUNNER_PY="${SPARK_SQL_RUNNER_PY:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/spark_sql_file_runner.py}"

_safe_source_spark_file() {
  local f="$1"
  local had_u=0
  case "$-" in *u*) had_u=1; set +u ;; esac
  export SPARK_ENV_LOADED="${SPARK_ENV_LOADED-}"
  # shellcheck disable=SC1090
  source "${f}"
  if [[ "${had_u}" -eq 1 ]]; then set -u; fi
}

_pick_spark_conf_dir() {
  local d
  shopt -s nullglob
  for d in \
    /etc/spark3/conf.cloudera.SPARK3_ON_YARN* \
    /etc/spark3/conf.cloudera.spark3_on_yarn* \
    /etc/spark3/conf.cloudera.*; do
    if [[ -d "${d}" && -f "${d}/spark-defaults.conf" ]]; then
      echo "${d}"
      shopt -u nullglob 2>/dev/null || true
      return 0
    fi
  done
  shopt -u nullglob 2>/dev/null || true
  if [[ -d /etc/spark3/conf && -f /etc/spark3/conf/spark-defaults.conf ]]; then
    echo /etc/spark3/conf
  fi
}

_spark_sql_bin_dirs() {
  local d
  if [[ -n "${SPARK_HOME:-}" && -d "${SPARK_HOME}/bin" ]]; then
    printf '%s\n' "${SPARK_HOME}/bin"
  fi
  for d in \
    /opt/cloudera/parcels/spark3/bin \
    /opt/cloudera/parcels/CDH/lib/spark3/bin \
    /opt/cloudera/parcels/CDH-*/lib/spark3/bin \
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
  shopt -s nullglob
  for root in \
    /opt/cloudera/parcels/spark3 \
    /opt/cloudera/parcels/CDH/lib/spark3 \
    /opt/cloudera/parcels/CDH-*/lib/spark3 \
    /opt/cloudera/parcels/SPARK3/lib/spark3; do
    if [[ -d "${root}/bin" ]]; then
      # shellcheck disable=SC2086
      export SPARK_HOME="${root}"
      case ":${PATH}:" in
        *":${SPARK_HOME}/bin:"*) ;;
        *) export PATH="${SPARK_HOME}/bin:${PATH}" ;;
      esac
      return 0
    fi
  done
  shopt -u nullglob 2>/dev/null || true
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

  local f conf_dir
  for f in \
    /opt/cloudera/parcels/CDH/lib/spark3/bin/load-spark-env.sh \
    /opt/cloudera/parcels/spark3/bin/load-spark-env.sh; do
    if [[ -f "${f}" ]]; then
      _safe_source_spark_file "${f}"
      break
    fi
  done

  conf_dir="${SPARK_CONF_DIR:-$(_pick_spark_conf_dir)}"
  if [[ -n "${conf_dir}" ]]; then
    export SPARK_CONF_DIR="${conf_dir}"
    if [[ -f "${SPARK_CONF_DIR}/spark-env.sh" ]]; then
      _safe_source_spark_file "${SPARK_CONF_DIR}/spark-env.sh"
    fi
  fi

  shopt -s nullglob
  for f in /etc/spark3/conf.cloudera.*/spark-env.sh; do
    [[ -f "${f}" ]] && _safe_source_spark_file "${f}"
  done
  shopt -u nullglob 2>/dev/null || true

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

_spark_submit_bin() {
  local bin="${SPARK_HOME:-}/bin/spark-submit"
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return 0
  fi
  command -v spark-submit 2>/dev/null && return 0
  return 1
}

# CDP client 에 SparkSQLCLIDriver 가 classpath 에 없을 때 jar 디렉터리 전체 추가
_build_spark_sql_classpath() {
  local cp="" j dir
  for dir in \
    "${SPARK_HOME}/jars" \
    /opt/cloudera/parcels/CDH/lib/hive/lib \
    /opt/cloudera/parcels/CDH-*/lib/hive/lib \
    /opt/cloudera/parcels/CDH/lib/spark3/jars \
    /opt/cloudera/parcels/CDH-*/lib/spark3/jars; do
    [[ -d "${dir}" ]] || continue
    shopt -s nullglob
    for j in "${dir}"/*.jar; do
      cp="${cp}:${j}"
    done
    shopt -u nullglob 2>/dev/null || true
  done
  echo "${cp#:}"
}

resolve_spark_sql_cmd() {
  source_spark_environment

  if [[ -n "${SPARK_SQL_CMD:-}" ]]; then
    if [[ -x "${SPARK_SQL_CMD}" ]] || command -v "${SPARK_SQL_CMD}" >/dev/null 2>&1; then
      echo "${SPARK_SQL_CMD}"
      return 0
    fi
    echo "[ERROR] SPARK_SQL_CMD 를 실행할 수 없음: ${SPARK_SQL_CMD}" >&2
    return 1
  fi

  local cmd dir path submit
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

  submit="$(_spark_submit_bin 2>/dev/null)" || true
  if [[ -n "${submit}" ]]; then
    echo "spark-submit:${SPARK_SQL_MAIN_CLASS} (fallback pyspark: ${SPARK_SQL_RUNNER_PY})"
    return 0
  fi
  return 1
}

_run_spark_submit_java_cli() {
  local file="$1"
  shift
  local sql_args=("$@")
  local submit cp
  submit="$(_spark_submit_bin)" || return 1
  cp="$(_build_spark_sql_classpath)"
  local extra=()
  if [[ -n "${cp}" ]]; then
    extra+=(--driver-class-path "${cp}" --conf "spark.driver.extraClassPath=${cp}")
  fi
  echo "[INFO] spark-submit ${SPARK_SQL_MAIN_CLASS} (driver classpath)" >&2
  "${submit}" "${extra[@]}" --class "${SPARK_SQL_MAIN_CLASS}" \
    "${sql_args[@]}" -f "${file}"
}

_exec_spark_submit_pyspark() {
  local file="$1"
  shift
  local sql_args=("$@")
  local submit cp
  submit="$(_spark_submit_bin)" || return 1
  cp="$(_build_spark_sql_classpath)"
  local extra=()
  if [[ -n "${cp}" ]]; then
    extra+=(--driver-class-path "${cp}" --conf "spark.driver.extraClassPath=${cp}")
  fi
  if [[ ! -f "${SPARK_SQL_RUNNER_PY}" ]]; then
    return 1
  fi
  echo "[INFO] spark-submit PySpark runner (SparkSQLCLIDriver unavailable)" >&2
  exec "${submit}" "${extra[@]}" "${sql_args[@]}" "${SPARK_SQL_RUNNER_PY}" "${file}"
}

exec_spark_sql_file() {
  local file="$1"
  shift
  local sql_args=("$@")

  source_spark_environment

  local runner dir path
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

  if _run_spark_submit_java_cli "${file}" "${sql_args[@]}"; then
    exit 0
  fi
  echo "[WARN] SparkSQLCLIDriver failed — trying PySpark SQL runner" >&2

  _exec_spark_submit_pyspark "${file}" "${sql_args[@]}"

  echo "[ERROR] Spark SQL 실행 실패 (SparkSQLCLIDriver 및 PySpark runner)" >&2
  echo "  SPARK_CONF_DIR=${SPARK_CONF_DIR:-unset} SPARK_HOME=${SPARK_HOME:-unset}" >&2
  exit 1
}
