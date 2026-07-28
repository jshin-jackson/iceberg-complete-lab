#!/usr/bin/env bash
# 합성 Parquet 생성 (Python 3 필수 — `python` 이 2.x 이면 SyntaxError)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SYN="${ROOT}/synthetic-data"
PY="${PYTHON:-python3}"

if ! command -v "${PY}" >/dev/null 2>&1; then
  echo "[ERROR] ${PY} 없음. Python 3.8+ 설치 또는 PYTHON=/path/to/python3 지정" >&2
  exit 1
fi

"${PY}" - <<'PYCHECK'
import sys
if sys.version_info < (3, 8):
    sys.exit("Python 3.8+ 필요 (현재: {}.{})".format(*sys.version_info[:2]))
PYCHECK

cd "${SYN}"
"${PY}" -m pip install -r requirements.txt
exec "${PY}" generators/generate_ecommerce_data.py "$@"
