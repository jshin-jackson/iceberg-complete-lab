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
TS_PWD="${HIVE_SSL_TRUSTSTORE_PASSWORD:-Prlcflcy2ZOMhtUqb0GFyd6FXKSTZfMpSU4n7kXtMaG}"
if [[ -f "${TS}" ]]; then
  echo "OK: ${TS}"
  if command -v keytool >/dev/null 2>&1; then
    if keytool -list -keystore "${TS}" -storepass "${TS_PWD}" >/dev/null 2>&1; then
      echo "truststore 비밀번호: OK (keytool)"
    else
      echo "[ERROR] truststore JKS 를 열 수 없음 — HIVE_SSL_TRUSTSTORE_PASSWORD 가 CM 값과 다릅니다." >&2
      echo "        (Beeline: Keystore was tampered with, or password was incorrect)" >&2
      echo "        .env HIVE_SSL_TRUSTSTORE_PASSWORD 및 JDBC trustStorePassword= 를 CM 과 맞추세요." >&2
      exit 1
    fi
  else
    echo "[WARN] keytool 없음 — truststore 비밀번호는 beeline 전에 CM 값으로 맞춰 두세요"
  fi
else
  echo "[WARN] 없음: ${TS}"
fi

_beeline_select1() {
  local err
  err="$(mktemp)"
  if beeline -u "$1" --silent=true --showHeader=false --outputformat=tsv2 -e "SELECT 1 AS ok;" 2>"${err}"; then
    rm -f "${err}"
    return 0
  fi
  if grep -qE 'Keystore was tampered with|password was incorrect' "${err}" 2>/dev/null; then
    echo "[ERROR] SSL truststore 비밀번호 오류 (TLS 핸드shake 전 JKS 로드 실패)." >&2
    echo "        HIVE_SSL_TRUSTSTORE_PASSWORD 및 JDBC trustStorePassword= 를 CM truststore 와 일치시키세요." >&2
  fi
  cat "${err}" >&2
  rm -f "${err}"
  return 1
}

echo ""
echo "== JDBC URL (조립) =="
JDBC="$(build_hive_jdbc)"
echo "$(mask_hive_jdbc_for_log "${JDBC}")"
if [[ "${JDBC}" != *auth=KERBEROS* ]]; then
  echo "[WARN] URL에 auth=KERBEROS 없음 — principal만으로는 Broken pipe/reset 가능" >&2
fi
if [[ "${JDBC}" != *serviceDiscoveryMode=zooKeeper* ]]; then
  if [[ -n "${HIVE_ZK_QUORUM:-}" && "${HIVE_SERVER2_CONNECT:-zk}" == "zk" ]]; then
    echo "[ERROR] JDBC 가 ZK(2181) 가 아닙니다 — .env 의 옛 HIVE_SERVER2_JDBC(:10015) 를 제거/교체하세요." >&2
    echo "        git pull 후 .env.example Hive 섹션 복사 또는 HIVE_SERVER2_CONNECT=lb" >&2
  elif [[ "${JDBC}" == *":10015/"* || "${JDBC}" == *":10015;"* ]]; then
    echo "[WARN] HAProxy :10015 LB URL — CM 기본은 ZK(2181). Broken pipe 시 principal=hive/_HOST@REALM 확인" >&2
  fi
fi

echo ""
echo "== beeline SELECT 1 =="
if _beeline_select1 "${JDBC}"; then
  echo "beeline 연결 OK"
  exit 0
fi

# CM transport.mode=binary 가 일반 — HTTP 자동 재시도는 오히려 https+changeit 오류를 유발
if [[ "${HIVE_SERVER2_TRY_HTTP_PROBE:-false}" == "true" \
  && "${JDBC}" != *transportMode=http* \
  && "${JDBC}" != *serviceDiscoveryMode=zooKeeper* ]]; then
  echo ""
  echo "== beeline SELECT 1 (HTTP transport — TRY_HTTP_PROBE) =="
  _saved_jdbc="${HIVE_SERVER2_JDBC:-}"
  unset HIVE_SERVER2_JDBC
  export HIVE_SERVER2_TRANSPORT_MODE=http
  JDBC_HTTP="$(build_hive_jdbc)"
  echo "$(mask_hive_jdbc_for_log "${JDBC_HTTP}")"
  if _beeline_select1 "${JDBC_HTTP}"; then
    echo "beeline 연결 OK (HTTP — .env 에 HIVE_SERVER2_TRANSPORT_MODE=http)"
    exit 0
  fi
  if [[ -n "${_saved_jdbc}" ]]; then
    export HIVE_SERVER2_JDBC="${_saved_jdbc}"
  fi
fi

echo ""
echo "실패 시 확인:"
echo "  1) kinit 후 klist"
echo "  2) CM ZK JDBC: HIVE_SERVER2_JDBC 또는 HIVE_ZK_QUORUM (2181) — :10015 LB 는 CM JDBC 와 다를 수 있음"
echo "  3) HIVE_SSL_TRUSTSTORE_PASSWORD / JDBC trustStorePassword (keytool -list 로 검증)"
echo "  4) transport.mode=binary 이면 HTTP 재시도 불필요 (CM 설정과 동일하게)"
exit 1
