# Lab 05 — Time Travel & Branch (시간 여행)

**트랙:** Core  
**난이도:** 초급~중급

## 이 Lab에서 배우는 것

Iceberg는 데이터를 바꿀 때마다 **스냅샷**을 남깁니다. Time Travel은 “**예전 스냅샷 기준으로** 테이블을 조회”하는 기능입니다.

### 엔진별 문법 (개념)

| 엔진 | 예시 문법 (Lab SQL 참고) |
|------|-------------------------|
| **Spark** | `TIMESTAMP AS OF`, `VERSION AS OF` |
| **Hive / Impala** | `FOR SYSTEM_TIME AS OF` |

같은 “과거 시점 읽기”를 엔진마다 표현만 다릅니다.

### Tag · Branch (개념)

- **Tag**: 특정 스냅샷에 **이름**을 붙여 두기 (예: `month_end_2024_01`)
- **Branch**: (Iceberg 버전·설정에 따라) **작업용 줄기** — 고급 워크플로; Lab에서는 tag·snapshots 조회 위주

실무에서는 “실수로 덮어쓴 뒤 어제 상태로 조회”, “감사용 특정 시점 스냅샷” 등에 씁니다.

## 실행 방법

```bash
cd labs/lab-05-time-travel
./run.sh
./validate_all.sh
```

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark** | ● tag·**snapshots** 메타 조회, AS OF 조회 | — |
| **Hive** | ○ **FOR SYSTEM_TIME** 조회 | — |
| **Impala** | ○ COUNT 등으로 시점별 결과 확인 | — |

## 선행 Lab

**Lab 04** — `merge_demo` 등 **스냅샷이 여러 개 쌓인** 테이블이 있어야 time travel 연습이 의미 있습니다.

## 다음 Lab

**Lab 06** — UPDATE/DELETE를 **어떻게 파일에 반영할지** (Copy-on-Write vs Merge-on-Read)를 배웁니다.
