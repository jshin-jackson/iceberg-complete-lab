#!/usr/bin/env bash
# Beeline SQL 파일 실행
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/env.sh"
FILE="${1:?usage: run_hive_sql.sh file.sql}"
JDBC="${HIVE_SERVER2_JDBC:?HIVE_SERVER2_JDBC 설정 필요}"
beeline -u "${JDBC}" -f "${FILE}"
