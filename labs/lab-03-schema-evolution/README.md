# Lab 03 — Schema Evolution (스키마 진화)

**트랙:** Core  
**난이도:** 초급

## 이 Lab에서 배우는 것

테이블 **컬럼 구조(스키마)** 를 시간이 지나며 바꾸는 일은 흔합니다. 예: 새 필드 추가, 이름 변경, (지원 시) 컬럼 삭제.

전통적인 “Parquet 파일만 있는” 레이크에서는 스키마 변경이 **파일 전체 재작성**으로 이어지기 쉽습니다.  
Iceberg는 **메타데이터에 스키마 버전**을 기록해, 가능한 변경은 **ALTER TABLE** 만으로 처리합니다.

이 Lab SQL 예시:

- **ADD COLUMN** — 새 컬럼 추가
- **RENAME COLUMN** — 컬럼 이름 변경
- **DROP COLUMN** — (Iceberg·엔진 버전에 따라) 컬럼 제거

## 실행 방법

```bash
cd labs/lab-03-schema-evolution
./run.sh
./validate_all.sh
```

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark** | ● **ALTER TABLE** 실행 | — |
| **Hive / Impala** | ○ 변경된 스키마로 **SELECT** (Impala는 **`REFRESH`** 후 조회하는 경우가 많음) | 행·컬럼이 기대와 일치 |

**팁:** Impala는 HMS 메타 캐시 때문에 스키마 변경 직후 `REFRESH db.table` 또는 `INVALIDATE METADATA`가 필요할 수 있습니다. Lab SQL·검증 스크립트 주석을 확인하세요.

## 선행 Lab

**Lab 01** — 특히 **`customers`** 같은 기본 테이블이 Lab 01에서 만들어져 있어야 합니다.

## 다음 Lab

**Lab 04** — 여러 행을 한 번에 맞추는 **MERGE INTO**와 **ACID(스냅샷 단위 일관성)** 를 배웁니다.
