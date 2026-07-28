#!/usr/bin/env bash
# CDP edge: HDFS HA — Standby NN WARN 방지 (클러스터 /etc/hadoop/conf 사용)

source_hadoop_environment() {
  if [[ "${HADOOP_ENV_SOURCED:-}" == "1" ]]; then
    return 0
  fi

  export HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-/etc/hadoop/conf}"
  export YARN_CONF_DIR="${YARN_CONF_DIR:-${HADOOP_CONF_DIR}}"

  if [[ ! -d "${HADOOP_CONF_DIR}" ]]; then
    echo "[WARN] HADOOP_CONF_DIR 없음: ${HADOOP_CONF_DIR} (Standby NN WARN 가능)" >&2
    return 0
  fi

  # Spark/YARN 이 NameNode failover 설정을 읽도록 classpath 에 conf 디렉터리 포함
  if [[ -z "${HADOOP_CLASSPATH:-}" ]]; then
    export HADOOP_CLASSPATH="${HADOOP_CONF_DIR}"
  elif [[ "${HADOOP_CLASSPATH}" != *"${HADOOP_CONF_DIR}"* ]]; then
    export HADOOP_CLASSPATH="${HADOOP_CONF_DIR}:${HADOOP_CLASSPATH}"
  fi

  export HADOOP_ENV_SOURCED=1
  return 0
}

# spark-submit --conf 용 (선택 .env HDFS_DEFAULT_FS / SPARK_YARN_STAGING_DIR)
hadoop_spark_extra_conf_args() {
  local args=()
  if [[ -n "${HDFS_DEFAULT_FS:-}" ]]; then
    args+=(--conf "spark.hadoop.fs.defaultFS=${HDFS_DEFAULT_FS}")
  fi
  if [[ -n "${SPARK_YARN_STAGING_DIR:-}" ]]; then
    args+=(--conf "spark.yarn.stagingDir=${SPARK_YARN_STAGING_DIR}")
  fi
  if [[ ${#args[@]} -gt 0 ]]; then
    printf '%s\n' "${args[@]}"
  fi
}
