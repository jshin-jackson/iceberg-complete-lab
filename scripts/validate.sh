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

echo "== Beeline (JDBC 설정 확인) =="
if [[ "${HIVE_SERVER2_JDBC}" == *REPLACE* ]]; then
  echo "[WARN] HIVE_SERVER2_JDBC 를 .env 에 설정하세요"
else
  echo "JDBC OK: ${HIVE_SERVER2_JDBC}"
fi

echo "== Impala =="
if [[ "${IMPALA_DAEMON}" == *REPLACE* ]]; then
  echo "[WARN] IMPALA_DAEMON 을 .env 에 설정하세요"
else
  echo "Impala OK: ${IMPALA_DAEMON}"
fi

echo "validate.sh: 기본 검증 완료"
