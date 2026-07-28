#!/usr/bin/env bash
# Beeline SQL 파일 실행 (Kerberos + SSL JDBC — CDP HiveServer2)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/env.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/hadoop_env.sh"
source_hadoop_environment
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/hive_jdbc.sh"

FILE="${1:?usage: run_hive_sql.sh file.sql}"

if ! klist -s 2>/dev/null; then
  echo "[ERROR] Kerberos ticket 없음. kinit 후 beeline 실행." >&2
  exit 1
fi

JDBC="$(build_hive_jdbc)"
if [[ "${HIVE_JDBC_DEBUG:-false}" == "true" ]]; then
  echo "[DEBUG] JDBC: $(mask_hive_jdbc_for_log "${JDBC}")" >&2
fi

exec beeline -u "${JDBC}" --silent=false --showHeader=true -f "${FILE}"
