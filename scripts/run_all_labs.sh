#!/usr/bin/env bash
# 모든 Lab run + validate_all (실패 시 중단)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for lab in "${ROOT}"/labs/lab-*/; do
  name="$(basename "${lab}")"
  echo "======== ${name} ========"
  if [[ -x "${lab}/run.sh" ]]; then
    (cd "${lab}" && ./run.sh)
  fi
  if [[ -x "${lab}/validate_all.sh" ]]; then
    (cd "${lab}" && ./validate_all.sh)
  fi
done
echo "run_all_labs.sh 완료"
