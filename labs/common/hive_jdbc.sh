#!/usr/bin/env bash
# HiveServer2 JDBC URL 조립 (Beeline)

_jdbc_has_kerberos_params() {
  [[ "${1}" == *principal=* ]] || [[ "${1}" == *auth=KERBEROS* ]]
}

_jdbc_cmf_conf_dir() {
  printf '%s' "${CMF_CONF_DIR:-${HIVE_CMF_CONF_DIR:-/var/lib/cloudera-scm-agent/agent-cert}}"
}

# CM UI JDBC 예시의 {{CMF_CONF_DIR}} → edge 실경로
_jdbc_expand_placeholders() {
  local u="$1"
  local cmf
  cmf="$(_jdbc_cmf_conf_dir)"
  u="${u//\{\{CMF_CONF_DIR\}\}/${cmf}}"
  printf '%s' "${u}"
}

# principal 만 있고 auth=KERBEROS 가 없으면 Beeline 이 Broken pipe 로 끊기는 경우가 많음
_jdbc_ensure_kerberos_auth() {
  local u="$1"
  if [[ "${u}" == *principal=* && "${u}" != *auth=KERBEROS* ]]; then
    u="${u//;principal=/;auth=KERBEROS;principal=}"
  fi
  printf '%s' "${u}"
}

_jdbc_append_ssl() {
  local url="$1"
  local ts pwd ttype
  if [[ "${HIVE_SERVER2_SSL:-true}" != "true" ]]; then
    printf '%s' "${url}"
    return
  fi
  ts="${HIVE_SSL_TRUSTSTORE:-$(_jdbc_cmf_conf_dir)/cm-auto-global_truststore.jks}"
  pwd="${HIVE_SSL_TRUSTSTORE_PASSWORD:-Prlcflcy2ZOMhtUqb0GFyd6FXKSTZfMpSU4n7kXtMaG}"
  ttype="${HIVE_SSL_TRUSTSTORE_TYPE:-jks}"
  printf '%s' "${url};ssl=true;trustStoreType=${ttype};sslTrustStore=${ts};trustStorePassword=${pwd}"
}

_jdbc_sync_truststore_password() {
  local u="$1"
  local pwd="${HIVE_SSL_TRUSTSTORE_PASSWORD:-}"
  if [[ -n "${pwd}" && "${u}" == *trustStorePassword=* ]]; then
    echo "${u}" | sed -E "s/trustStorePassword=[^;]*/trustStorePassword=${pwd}/g"
  else
    printf '%s' "${u}"
  fi
}

_jdbc_finalize() {
  local u
  u="$(_jdbc_ensure_kerberos_auth "$(_jdbc_expand_placeholders "$1")")"
  _jdbc_sync_truststore_password "${u}"
}

# HAProxy LB (:10015) 한 줄 JDBC — CM ZK(2181) 와 다름
_jdbc_is_haproxy_lb_url() {
  [[ "${1}" == *":10015/"* || "${1}" == *":10015;"* ]]
}

_hive_server2_prefer_zk() {
  [[ "${HIVE_SERVER2_CONNECT:-zk}" == "zk" && -n "${HIVE_ZK_QUORUM:-}" ]]
}

build_hive_jdbc() {
  local skip_full_jdbc=false
  if [[ -n "${HIVE_SERVER2_JDBC:-}" && "${HIVE_SERVER2_JDBC}" != *REPLACE* ]] \
    && _jdbc_is_haproxy_lb_url "${HIVE_SERVER2_JDBC}" \
    && _hive_server2_prefer_zk; then
    echo "[WARN] HIVE_SERVER2_JDBC 가 HAProxy :10015 입니다 — HIVE_ZK_QUORUM(CM JDBC) 으로 조립합니다." >&2
    echo "       LB 고정: HIVE_SERVER2_CONNECT=lb + HIVESERVER2_LOAD_BALANCER (docs/03-cloudera-integration.md HAProxy)" >&2
    skip_full_jdbc=true
  fi

  if [[ "${skip_full_jdbc}" != "true" ]] \
    && [[ -n "${HIVE_SERVER2_JDBC:-}" && "${HIVE_SERVER2_JDBC}" != *REPLACE* ]] \
    && _jdbc_has_kerberos_params "${HIVE_SERVER2_JDBC}"; then
    _jdbc_finalize "${HIVE_SERVER2_JDBC}"
    return
  fi

  if [[ -n "${HIVE_SERVER2_JDBC:-}" && "${HIVE_SERVER2_JDBC}" != *REPLACE* ]]; then
    echo "[WARN] HIVE_SERVER2_JDBC 에 principal/auth 없음 — HIVESERVER2_* / HIVE_ZK_* 로 URL 재조립합니다." >&2
  fi

  local db principal url transport http_path quorum zk_ns
  principal="${HIVE_SERVER2_PRINCIPAL:?HIVE_SERVER2_PRINCIPAL (.env)}"

  if [[ -n "${HIVE_ZK_QUORUM:-}" ]]; then
    quorum="${HIVE_ZK_QUORUM}"
    zk_ns="${HIVE_ZK_NAMESPACE:-hiveserver2}"
    db="${HIVE_SERVER2_JDBC_DATABASE-}"
    if [[ -z "${db}" ]]; then
      url="jdbc:hive2://${quorum}/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=${zk_ns};auth=KERBEROS;principal=${principal}"
    else
      url="jdbc:hive2://${quorum}/${db};serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=${zk_ns};auth=KERBEROS;principal=${principal}"
    fi
    url="$(_jdbc_append_ssl "${url}")"
    if [[ -n "${HIVE_SERVER2_JDBC_EXTRA:-}" ]]; then
      url="${url};${HIVE_SERVER2_JDBC_EXTRA}"
    fi
    _jdbc_finalize "${url}"
    return
  fi

  local host port
  if [[ -n "${HIVESERVER2_LOAD_BALANCER:-}" ]]; then
    host="${HIVESERVER2_LOAD_BALANCER%%:*}"
    port="${HIVESERVER2_LOAD_BALANCER##*:}"
  else
    host="${HIVESERVER2_HOST:?HIVESERVER2_HOST, HIVESERVER2_LOAD_BALANCER, or HIVE_ZK_QUORUM}"
    port="${HIVESERVER2_PORT:-10015}"
  fi
  db="${HIVE_SERVER2_JDBC_DATABASE:-default}"
  if [[ "${HIVE_SERVER2_CONNECT:-}" == "lb" && -n "${HIVE_SERVER2_LB_PRINCIPAL:-}" ]]; then
    principal="${HIVE_SERVER2_LB_PRINCIPAL}"
  fi

  url="jdbc:hive2://${host}:${port}/${db};auth=KERBEROS;principal=${principal}"

  transport="${HIVE_SERVER2_TRANSPORT_MODE:-}"
  http_path="${HIVE_SERVER2_HTTP_PATH:-cliservice}"
  if [[ "${transport}" == "http" ]]; then
    url="${url};transportMode=http;httpPath=${http_path}"
  fi

  url="$(_jdbc_append_ssl "${url}")"

  if [[ -n "${HIVE_SERVER2_JDBC_EXTRA:-}" ]]; then
    url="${url};${HIVE_SERVER2_JDBC_EXTRA}"
  fi

  _jdbc_finalize "${url}"
}

mask_hive_jdbc_for_log() {
  echo "$1" | sed -E 's/trustStorePassword=[^;]*/trustStorePassword=***/g'
}
