#!/usr/bin/env bash
# HiveServer2 JDBC URL 조립 (Beeline) — CM ZK discovery 형식

_jdbc_has_kerberos_params() {
  [[ "${1}" == *principal=* ]] || [[ "${1}" == *auth=KERBEROS* ]]
}

_jdbc_cmf_conf_dir() {
  printf '%s' "${CMF_CONF_DIR:-${HIVE_CMF_CONF_DIR:-/var/lib/cloudera-scm-agent/agent-cert}}"
}

_jdbc_expand_placeholders() {
  local u="$1"
  local cmf
  cmf="$(_jdbc_cmf_conf_dir)"
  u="${u//\{\{CMF_CONF_DIR\}\}/${cmf}}"
  printf '%s' "${u}"
}

# 이 클러스터 CM JDBC 는 auth=KERBEROS 없이 principal 만 사용 (beeline 대화형과 동일)
_jdbc_ensure_kerberos_auth() {
  local u="$1"
  if [[ "${HIVE_SERVER2_ENSURE_KERBEROS_AUTH:-false}" == "true" \
    && "${u}" == *principal=* && "${u}" != *auth=KERBEROS* ]]; then
    u="${u//;principal=/;auth=KERBEROS;principal=}"
  fi
  printf '%s' "${u}"
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

_jdbc_is_haproxy_lb_url() {
  [[ "${1}" == *":10015/"* || "${1}" == *":10015;"* ]]
}

_hive_server2_prefer_zk() {
  [[ "${HIVE_SERVER2_CONNECT:-zk}" == "zk" && -n "${HIVE_ZK_QUORUM:-}" ]]
}

# edge 에서 성공한 CM/beeline JDBC 와 동일한 파라미터 순서·이름
_jdbc_build_zk_url() {
  local quorum="$1" principal="$2" db="$3"
  local ts pwd ttype kstype retries zk_ns zk_ks zk_ts
  ts="${HIVE_SSL_TRUSTSTORE:-$(_jdbc_cmf_conf_dir)/cm-auto-global_truststore.jks}"
  pwd="${HIVE_SSL_TRUSTSTORE_PASSWORD:-Prlcflcy2ZOMhtUqb0GFyd6FXKSTZfMpSU4n7kXtMaG}"
  ttype="${HIVE_SSL_TRUSTSTORE_TYPE:-jks}"
  kstype="${HIVE_KEYSTORE_TYPE:-jks}"
  retries="${HIVE_SERVER2_JDBC_RETRIES:-5}"
  zk_ns="${HIVE_ZK_NAMESPACE:-hiveserver2}"
  zk_ks="${HIVE_ZK_KEYSTORE_TYPE:-jks}"
  zk_ts="${HIVE_ZK_TRUSTSTORE_TYPE:-jks}"

  if [[ "${HIVE_SERVER2_SSL:-true}" != "true" ]]; then
    printf 'jdbc:hive2://%s/%s;keyStoreType=%s;principal=%s;retries=%s;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=%s;zookeeperKeyStoreType=%s;zookeeperTrustStoreType=%s' \
      "${quorum}" "${db}" "${kstype}" "${principal}" "${retries}" "${zk_ns}" "${zk_ks}" "${zk_ts}"
    return
  fi

  printf 'jdbc:hive2://%s/%s;keyStoreType=%s;principal=%s;retries=%s;serviceDiscoveryMode=zooKeeper;ssl=true;sslTrustStore=%s;trustStorePassword=%s;trustStoreType=%s;zooKeeperNamespace=%s;zookeeperKeyStoreType=%s;zookeeperTrustStoreType=%s' \
    "${quorum}" "${db}" "${kstype}" "${principal}" "${retries}" "${ts}" "${pwd}" "${ttype}" "${zk_ns}" "${zk_ks}" "${zk_ts}"
}

build_hive_jdbc() {
  local skip_full_jdbc=false
  if [[ -n "${HIVE_SERVER2_JDBC:-}" && "${HIVE_SERVER2_JDBC}" != *REPLACE* ]] \
    && _jdbc_is_haproxy_lb_url "${HIVE_SERVER2_JDBC}" \
    && _hive_server2_prefer_zk; then
    echo "[WARN] HIVE_SERVER2_JDBC 가 HAProxy :10015 입니다 — HIVE_ZK_QUORUM(CM JDBC) 으로 조립합니다." >&2
    skip_full_jdbc=true
  fi

  if [[ "${skip_full_jdbc}" != "true" ]] \
    && [[ -n "${HIVE_SERVER2_JDBC:-}" && "${HIVE_SERVER2_JDBC}" != *REPLACE* ]] \
    && _jdbc_has_kerberos_params "${HIVE_SERVER2_JDBC}"; then
    _jdbc_finalize "${HIVE_SERVER2_JDBC}"
    return
  fi

  if [[ -n "${HIVE_SERVER2_JDBC:-}" && "${HIVE_SERVER2_JDBC}" != *REPLACE* ]]; then
    echo "[WARN] HIVE_SERVER2_JDBC 에 principal 없음 — HIVE_ZK_* 로 URL 재조립합니다." >&2
  fi

  local db principal url transport http_path quorum
  principal="${HIVE_SERVER2_PRINCIPAL:?HIVE_SERVER2_PRINCIPAL (.env)}"

  if [[ -n "${HIVE_ZK_QUORUM:-}" ]]; then
    quorum="${HIVE_ZK_QUORUM}"
    db="${HIVE_SERVER2_JDBC_DATABASE:-default}"
    url="$(_jdbc_build_zk_url "${quorum}" "${principal}" "${db}")"
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

  url="jdbc:hive2://${host}:${port}/${db};keyStoreType=${HIVE_KEYSTORE_TYPE:-jks};principal=${principal};retries=${HIVE_SERVER2_JDBC_RETRIES:-5}"
  transport="${HIVE_SERVER2_TRANSPORT_MODE:-}"
  http_path="${HIVE_SERVER2_HTTP_PATH:-cliservice}"
  if [[ "${transport}" == "http" ]]; then
    url="${url};transportMode=http;httpPath=${http_path}"
  fi
  if [[ "${HIVE_SERVER2_SSL:-true}" == "true" ]]; then
    url="${url};ssl=true;sslTrustStore=${HIVE_SSL_TRUSTSTORE:-$(_jdbc_cmf_conf_dir)/cm-auto-global_truststore.jks};trustStorePassword=${HIVE_SSL_TRUSTSTORE_PASSWORD:-Prlcflcy2ZOMhtUqb0GFyd6FXKSTZfMpSU4n7kXtMaG};trustStoreType=${HIVE_SSL_TRUSTSTORE_TYPE:-jks}"
  fi
  if [[ -n "${HIVE_SERVER2_JDBC_EXTRA:-}" ]]; then
    url="${url};${HIVE_SERVER2_JDBC_EXTRA}"
  fi
  _jdbc_finalize "${url}"
}

mask_hive_jdbc_for_log() {
  echo "$1" | sed -E 's/trustStorePassword=[^;]*/trustStorePassword=***/g'
}
