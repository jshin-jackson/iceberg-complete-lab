#!/usr/bin/env bash
# Lab .env 기준 beeline (CM ZK JDBC — kinit 선행)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMMON="${ROOT}/labs/common"
# shellcheck disable=SC1091
source "${COMMON}/env.sh"
# shellcheck disable=SC1091
source "${COMMON}/hadoop_env.sh"
source_hadoop_environment
# shellcheck disable=SC1091
source "${COMMON}/hive_jdbc.sh"

if ! klist -s 2>/dev/null; then
  echo "[ERROR] Kerberos ticket 없음. kinit -kt \${KERBEROS_KEYTAB} \${KERBEROS_PRINCIPAL}" >&2
  exit 1
fi

JDBC="$(build_hive_jdbc)"
export BEELINE_JDBC_URL="${JDBC}"
exec beeline -u "${JDBC}" "$@"
