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
klist || { echo "kinit 필요: kinit -kt \${KERBEROS_KEYTAB} \${KERBEROS_PRINCIPAL}"; exit 1; }

echo ""
echo "== Truststore =="
TS="${HIVE_SSL_TRUSTSTORE:-/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_truststore.jks}"
if [[ -f "${TS}" ]]; then
  echo "OK: ${TS}"
else
  echo "[WARN] 없음: ${TS}"
fi

echo ""
echo "== JDBC URL (조립) =="
JDBC="$(build_hive_jdbc)"
echo "$(mask_hive_jdbc_for_log "${JDBC}")"

echo ""
echo "== beeline SELECT 1 =="
if beeline -u "${JDBC}" --silent=true --showHeader=false --outputformat=tsv2 -e "SELECT 1 AS ok;"; then
  echo "beeline 연결 OK"
else
  echo ""
  echo "실패 시 확인:"
  echo "  1) CM HiveServer2 principal = .env HIVE_SERVER2_PRINCIPAL (hive/<host>@REALM)"
  echo "  2) kinit REALM 과 principal REALM 일치"
  echo "  3) Connection reset → SSL: HIVE_SERVER2_SSL=true + truststore"
  echo "  4) HTTP HS2 이면: HIVE_SERVER2_TRANSPORT_MODE=http HIVE_SERVER2_HTTP_PATH=cliservice"
  echo "  5) .env HIVE_SERVER2_JDBC 가 principal 없는 짧은 URL 이면 삭제/수정"
  exit 1
fi
