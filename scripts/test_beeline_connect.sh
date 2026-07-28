#!/usr/bin/env bash
# Beeline / HiveServer2 연결 진단
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMMON="${ROOT}/labs/common"
# shellcheck disable=SC1091
source "${COMMON}/env.sh"
# shellcheck disable=SC1091
source "${COMMON}/hadoop_env.sh"
source_hadoop_environment
# shellcheck disable=SC1091
source "${COMMON}/hive_jdbc.sh"

echo "== Kerberos =="
if ! klist; then
  echo "kinit 필요: kinit -kt \${KERBEROS_KEYTAB} \${KERBEROS_PRINCIPAL}"
  exit 1
fi
if ! klist -s 2>/dev/null; then
  echo "[ERROR] ticket 만료. kinit 다시 실행." >&2
  exit 1
fi

echo ""
echo "== Truststore =="
TS="${HIVE_SSL_TRUSTSTORE:-/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_truststore.jks}"
if [[ -f "${TS}" ]]; then
  echo "OK: ${TS}"
else
  echo "[WARN] 없음: ${TS}"
fi

_beeline_select1() {
  beeline -u "$1" --silent=true --showHeader=false --outputformat=tsv2 -e "SELECT 1 AS ok;"
}

echo ""
echo "== JDBC URL (조립) =="
JDBC="$(build_hive_jdbc)"
echo "$(mask_hive_jdbc_for_log "${JDBC}")"
if [[ "${JDBC}" != *auth=KERBEROS* ]]; then
  echo "[WARN] URL에 auth=KERBEROS 없음 — principal만으로는 Broken pipe/reset 가능" >&2
fi

echo ""
echo "== beeline SELECT 1 (현재 transport) =="
if _beeline_select1 "${JDBC}"; then
  echo "beeline 연결 OK"
  exit 0
fi

if [[ "${JDBC}" != *transportMode=http* && "${HIVE_SERVER2_SKIP_HTTP_PROBE:-false}" != "true" ]]; then
  echo ""
  echo "== beeline SELECT 1 (HTTP transport 재시도) =="
  echo "CM HiveServer2 → hive.server2.transport.mode 가 http 이면 .env 에 고정:"
  echo "  HIVE_SERVER2_TRANSPORT_MODE=http"
  echo "  HIVE_SERVER2_HTTP_PATH=cliservice"
  _saved_jdbc="${HIVE_SERVER2_JDBC:-}"
  unset HIVE_SERVER2_JDBC
  export HIVE_SERVER2_TRANSPORT_MODE=http
  JDBC_HTTP="$(build_hive_jdbc)"
  echo "$(mask_hive_jdbc_for_log "${JDBC_HTTP}")"
  if _beeline_select1 "${JDBC_HTTP}"; then
    echo "beeline 연결 OK (HTTP transport — .env 에 HIVE_SERVER2_TRANSPORT_MODE=http 설정 권장)"
    exit 0
  fi
  if [[ -n "${_saved_jdbc}" ]]; then
    export HIVE_SERVER2_JDBC="${_saved_jdbc}"
  fi
fi

echo ""
echo "실패 시 확인:"
echo "  1) kinit 후 klist — Beeline 은 **lab 사용자 ticket** 필요 (root 만으로는 안 될 수 있음)"
echo "  2) JDBC: auth=KERBEROS;principal=...;ssl=true;sslTrustStore=... (trustStorePassword = CM agent truststore)"
echo "  3) CM HiveServer2 Principal 과 URL host FQDN 일치"
echo "  4) Broken pipe → HTTP transport (위 재시도) 또는 SSL/truststore 비밀번호"
echo "  5) Connection reset → principal/ssl 없는 짧은 JDBC URL"
exit 1
