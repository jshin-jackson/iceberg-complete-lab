#!/usr/bin/env bash
# Beeline SQL 파일 실행 (Kerberos + SSL JDBC — CDP HiveServer2)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/env.sh"
FILE="${1:?usage: run_hive_sql.sh file.sql}"

build_hive_jdbc() {
  if [[ -n "${HIVE_SERVER2_JDBC:-}" && "${HIVE_SERVER2_JDBC}" != *REPLACE* ]]; then
    printf '%s' "${HIVE_SERVER2_JDBC}"
    return
  fi
  local host port db principal url ts
  if [[ -n "${HIVESERVER2_LOAD_BALANCER:-}" ]]; then
    host="${HIVESERVER2_LOAD_BALANCER%%:*}"
    port="${HIVESERVER2_LOAD_BALANCER##*:}"
  else
    host="${HIVESERVER2_HOST:?HIVESERVER2_HOST or HIVESERVER2_LOAD_BALANCER or HIVE_SERVER2_JDBC}"
    port="${HIVESERVER2_PORT:-10015}"
  fi
  db="${HIVE_SERVER2_JDBC_DATABASE:-default}"
  principal="${HIVE_SERVER2_PRINCIPAL:?HIVE_SERVER2_PRINCIPAL 설정 (.env)}"
  url="jdbc:hive2://${host}:${port}/${db};principal=${principal}"
  if [[ "${HIVE_SERVER2_SSL:-true}" == "true" ]]; then
    ts="${HIVE_SSL_TRUSTSTORE:-/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_truststore.jks}"
    url="${url};ssl=true;sslTrustStore=${ts}"
    if [[ -n "${HIVE_SSL_TRUSTSTORE_PASSWORD:-}" ]]; then
      url="${url};trustStorePassword=${HIVE_SSL_TRUSTSTORE_PASSWORD}"
    fi
  fi
  printf '%s' "${url}"
}

JDBC="$(build_hive_jdbc)"
beeline -u "${JDBC}" -f "${FILE}"
