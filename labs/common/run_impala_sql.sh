#!/usr/bin/env bash
# Impala shell SQL 파일 실행
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/env.sh"
FILE="${1:?usage: run_impala_sql.sh file.sql}"
HOST="${IMPALA_DAEMON:?IMPALA_DAEMON 설정 필요}"
impala-shell -i "${HOST}" -k -f "${FILE}"
