#!/usr/bin/env bash
# Impala shell SQL 파일 실행 (Kerberos + SSL — CDP 7.3 impala-shell)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/env.sh"
FILE="${1:?usage: run_impala_sql.sh file.sql}"
HOST="${IMPALA_DAEMON:?IMPALA_DAEMON 설정 필요 (.env)}"
DB="${IMPALA_DEFAULT_DATABASE:-${LAB_DATABASE:-default}}"
PROTO="${IMPALA_PROTOCOL:-beeswax}"

ARGS=(-i "${HOST}" --protocol="${PROTO}" -d "${DB}" -k -f "${FILE}")

if [[ "${IMPALA_SSL:-true}" == "true" ]]; then
  ARGS+=(--ssl)
  CERT="${IMPALA_CA_CERT:-/var/lib/cloudera-scm-agent/agent-cert/cm-auto-global_cacerts.pem}"
  if [[ -f "${CERT}" ]]; then
    ARGS+=(--ca_cert="${CERT}")
  else
    echo "[WARN] IMPALA_SSL=true 이지만 CA cert 없음: ${CERT}" >&2
    echo "       .env 의 IMPALA_CA_CERT 를 확인하세요." >&2
  fi
fi

if [[ -n "${IMPALA_EXTRA_SHELL_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA=( ${IMPALA_EXTRA_SHELL_ARGS} )
  ARGS+=("${EXTRA[@]}")
fi

impala-shell "${ARGS[@]}"
