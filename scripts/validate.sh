#!/usr/bin/env bash
# 환경 검증 (edge 노드)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/labs/common/env.sh"

echo "== Kerberos =="
klist || { echo "kinit 실패"; exit 1; }

echo "== Spark =="
spark3-sql --version 2>&1 | head -1 || true

echo "== Hive Metastore =="
if [[ "${HMS_URI:-}" == *REPLACE* || -z "${HMS_URI:-}" ]]; then
  echo "[WARN] HMS_URI 를 .env 에 설정하세요 (thrift://host1:9083,thrift://host2:9083)"
else
  echo "HMS_URI OK: ${HMS_URI}"
fi

echo "== Beeline (HiveServer2) =="
if [[ "${HIVE_SERVER2_JDBC:-}" == *REPLACE* ]]; then
  echo "[WARN] HIVE_SERVER2_JDBC 또는 HIVESERVER2_LOAD_BALANCER + HIVE_SERVER2_PRINCIPAL 을 .env 에 설정하세요"
else
  HS2_SHOW="${HIVESERVER2_LOAD_BALANCER:-${HIVE_SERVER2_JDBC#jdbc:hive2://}}"
  HS2_SHOW="${HS2_SHOW%%/*}"
  echo "HiveServer2: ${HS2_SHOW} ssl=${HIVE_SERVER2_SSL:-true} principal=${HIVE_SERVER2_PRINCIPAL:-(JDBC 내장)}"
  if [[ "${HIVE_SERVER2_SSL:-true}" == "true" ]]; then
    TS="${HIVE_SSL_TRUSTSTORE:-/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_truststore.jks}"
    if [[ -f "${TS}" ]]; then
      echo "  truststore OK: ${TS}"
    else
      echo "[WARN] HIVE_SSL_TRUSTSTORE 파일 없음: ${TS}"
    fi
  fi
fi

echo "== Impala =="
if [[ "${IMPALA_DAEMON}" == *REPLACE* ]]; then
  echo "[WARN] IMPALA_DAEMON 을 .env 에 설정하세요 (예: coordinator:25003)"
else
  echo "Impala daemon: ${IMPALA_DAEMON}"
  echo "  protocol=${IMPALA_PROTOCOL:-beeswax} ssl=${IMPALA_SSL:-true} db=${IMPALA_DEFAULT_DATABASE:-${LAB_DATABASE:-default}}"
  if [[ "${IMPALA_SSL:-true}" == "true" ]]; then
    CERT="${IMPALA_CA_CERT:-/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_cacerts.pem}"
    if [[ -f "${CERT}" ]]; then
      echo "  ca_cert OK: ${CERT}"
    else
      echo "[WARN] IMPALA_CA_CERT 파일 없음: ${CERT}"
    fi
  fi
fi

echo "== Ozone warehouse =="
WH="${WAREHOUSE_OFS:-${WAREHOUSE:-}}"
if [[ -z "${WH}" || "${WH}" == *REPLACE* ]]; then
  echo "[WARN] WAREHOUSE_OFS 를 .env 에 설정하세요"
elif hdfs dfs -test -d "${WH}" 2>/dev/null; then
  echo "warehouse OK: ${WH}"
else
  echo "[WARN] warehouse 경로가 없거나 접근 불가: ${WH}"
  echo "       volume/bucket 생성: docs/04-ozone-storage.md"
  echo "       또는: ./scripts/setup_ozone_storage.sh --check"
fi

echo "validate.sh: 기본 검증 완료"
