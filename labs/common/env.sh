# Lab 공통 환경 (source only)
set -e
LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -f "${LAB_ROOT}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${LAB_ROOT}/.env"
  set +a
elif [[ -f "${LAB_ROOT}/.env.example" ]]; then
  echo "[WARN] .env 없음 — .env.example 로드 (호스트 값 수정 필요)"
  set -a
  # shellcheck disable=SC1091
  source "${LAB_ROOT}/.env.example"
  set +a
fi

export LAB_DATABASE="${LAB_DATABASE:-iceberg_lab}"
export ICEBERG_CATALOG="${ICEBERG_CATALOG:-hive_prod}"
export WAREHOUSE="${WAREHOUSE_OFS:-ofs://ozone1784520717/vol1/bucket1/warehouse}"

if [[ -n "${KERBEROS_KEYTAB:-}" && -n "${KERBEROS_PRINCIPAL:-}" ]]; then
  kinit -kt "${KERBEROS_KEYTAB}" "${KERBEROS_PRINCIPAL}" 2>/dev/null || klist -s || kinit -kt "${KERBEROS_KEYTAB}" "${KERBEROS_PRINCIPAL}"
fi
