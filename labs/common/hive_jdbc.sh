#!/usr/bin/env bash
# HiveServer2 JDBC URL 조립 (Beeline)

_jdbc_has_kerberos_params() {
  [[ "${1}" == *principal=* ]] || [[ "${1}" == *auth=KERBEROS* ]]
}

# principal 만 있고 auth=KERBEROS 가 없으면 Beeline 이 Broken pipe 로 끊기는 경우가 많음
_jdbc_ensure_kerberos_auth() {
  local u="$1"
  if [[ "${u}" == *principal=* && "${u}" != *auth=KERBEROS* ]]; then
    u="${u//;principal=/;auth=KERBEROS;principal=}"
  fi
  printf '%s' "${u}"
}

build_hive_jdbc() {
  if [[ -n "${HIVE_SERVER2_JDBC:-}" && "${HIVE_SERVER2_JDBC}" != *REPLACE* ]] \
    && _jdbc_has_kerberos_params "${HIVE_SERVER2_JDBC}"; then
    _jdbc_ensure_kerberos_auth "${HIVE_SERVER2_JDBC}"
    return
  fi

  if [[ -n "${HIVE_SERVER2_JDBC:-}" && "${HIVE_SERVER2_JDBC}" != *REPLACE* ]]; then
    echo "[WARN] HIVE_SERVER2_JDBC 에 principal/auth 없음 — HIVESERVER2_* 로 URL 재조립합니다." >&2
  fi

  local host port db principal url ts pwd transport http_path
  if [[ -n "${HIVESERVER2_LOAD_BALANCER:-}" ]]; then
    host="${HIVESERVER2_LOAD_BALANCER%%:*}"
    port="${HIVESERVER2_LOAD_BALANCER##*:}"
  else
    host="${HIVESERVER2_HOST:?HIVESERVER2_HOST or HIVESERVER2_LOAD_BALANCER}"
    port="${HIVESERVER2_PORT:-10015}"
  fi
  db="${HIVE_SERVER2_JDBC_DATABASE:-default}"
  principal="${HIVE_SERVER2_PRINCIPAL:?HIVE_SERVER2_PRINCIPAL (.env)}"

  url="jdbc:hive2://${host}:${port}/${db};auth=KERBEROS;principal=${principal}"

  transport="${HIVE_SERVER2_TRANSPORT_MODE:-}"
  http_path="${HIVE_SERVER2_HTTP_PATH:-cliservice}"
  if [[ "${transport}" == "http" ]]; then
    url="${url};transportMode=http;httpPath=${http_path}"
  fi

  if [[ "${HIVE_SERVER2_SSL:-true}" == "true" ]]; then
    ts="${HIVE_SSL_TRUSTSTORE:-/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_truststore.jks}"
    pwd="${HIVE_SSL_TRUSTSTORE_PASSWORD:-changeit}"
    url="${url};ssl=true;sslTrustStore=${ts};trustStorePassword=${pwd}"
  fi

  if [[ -n "${HIVE_SERVER2_JDBC_EXTRA:-}" ]]; then
    url="${url};${HIVE_SERVER2_JDBC_EXTRA}"
  fi

  _jdbc_ensure_kerberos_auth "${url}"
}

mask_hive_jdbc_for_log() {
  echo "$1" | sed -E 's/trustStorePassword=[^;]*/trustStorePassword=***/g'
}
