#!/usr/bin/env bash
# Ozone volume / bucket / warehouse prefix 준비 (edge 노드, Kerberos 이후)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/labs/common/env.sh"

MODE="${1:---check}"
VOL="${OZONE_VOLUME:?OZONE_VOLUME not set — configure .env}"
BUCKET="${OZONE_BUCKET:?OZONE_BUCKET not set}"
SVC="${OZONE_SERVICE_ID:-ozone1784520717}"
WH="${WAREHOUSE_OFS:-ofs://${SVC}/${VOL}/${BUCKET}/warehouse}"
GUIDE="${ROOT}/docs/04-ozone-storage.md"

usage() {
  echo "Usage: $0 [--check|--apply]"
  echo "  --check  volume/bucket/warehouse 존재 여부만 확인 (기본)"
  echo "  --apply  없으면 ozone volume/bucket create 및 hdfs mkdir -p warehouse"
  echo ""
  echo "상세 가이드: ${GUIDE}"
}

need_kinit() {
  if ! klist -s 2>/dev/null; then
    echo "[ERROR] Kerberos ticket 없음. kinit 후 다시 실행하세요."
    echo "  예: kinit -kt \"\${KERBEROS_KEYTAB}\" \"\${KERBEROS_PRINCIPAL}\""
    exit 1
  fi
}

volume_exists() {
  ozone sh volume info "${VOL}" >/dev/null 2>&1
}

bucket_exists() {
  ozone sh bucket info "${VOL}/${BUCKET}" >/dev/null 2>&1
}

warehouse_exists() {
  hdfs dfs -test -d "${WH}" >/dev/null 2>&1
}

print_plan() {
  echo "Ozone service ID: ${SVC}"
  echo "Volume:           ${VOL}"
  echo "Bucket:           ${VOL}/${BUCKET}"
  echo "Warehouse:        ${WH}"
  echo ""
}

case "${MODE}" in
  --check|--apply) ;;
  -h|--help) usage; exit 0 ;;
  *) echo "Unknown option: ${MODE}"; usage; exit 1 ;;
esac

need_kinit
print_plan

MISSING=0
if volume_exists; then
  echo "[OK] volume '${VOL}' exists"
else
  echo "[MISSING] volume '${VOL}'"
  MISSING=1
fi

if bucket_exists; then
  echo "[OK] bucket '${VOL}/${BUCKET}' exists"
else
  echo "[MISSING] bucket '${VOL}/${BUCKET}'"
  MISSING=1
fi

if warehouse_exists; then
  echo "[OK] warehouse path exists: ${WH}"
else
  echo "[MISSING] warehouse path: ${WH}"
  MISSING=1
fi

if [[ "${MODE}" == "--check" ]]; then
  if [[ "${MISSING}" -ne 0 ]]; then
    echo ""
    echo "생성 방법: ${GUIDE}"
    echo "또는 (ACL 권한이 있을 때): $0 --apply"
    exit 1
  fi
  echo ""
  echo "setup_ozone_storage.sh: check OK"
  exit 0
fi

# --apply
if ! volume_exists; then
  echo "Creating volume '${VOL}' ..."
  ozone sh volume create "${VOL}"
fi

if ! bucket_exists; then
  echo "Creating bucket '${VOL}/${BUCKET}' ..."
  ozone sh bucket create "${VOL}/${BUCKET}"
fi

if ! warehouse_exists; then
  echo "Creating warehouse prefix ${WH} ..."
  hdfs dfs -mkdir -p "${WH}"
fi

echo ""
echo "[NOTE] Ranger가 활성화된 CDP: Ozone 정책(cm_ozone)은 docs/04-ozone-storage.md §3 참고."
echo "       Ozone ACL은 클러스터마다 추가로 필요할 수 있습니다."
echo "       ${GUIDE}"
echo ""
echo "setup_ozone_storage.sh: apply 완료"
