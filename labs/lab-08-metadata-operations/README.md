# Lab 08 — Metadata Operations (메타데이터 유지보수)

**트랙:** Core  
**난이도:** 중급

## 이 Lab에서 배우는 것

Iceberg는 커밋마다 **스냅샷**과 **메타데이터 JSON**을 쌓습니다. Time travel·감사에는 유용하지만, 무한정 두면 **Ozone/HDFS 용량**과 **메타 조회 비용**이 커집니다.

### expire_snapshots

**일정 시간/개수보다 오래된 스냅샷**을 정리합니다.

- **주의:** 아직 다른 스냅샷·branch·tag가 참조하는 파일은 지우지 않도록 Iceberg 규칙이 있습니다.
- Time travel로 **아주 오래된 시점**을 조회할 수 없게 될 수 있으므로, **보존 정책**을 정하고 실행합니다.

Lab 07(compaction)이 **데이터 파일**을 정리한다면, Lab 08은 **히스토리(스냅샷) 메타** 쪽 정리에 가깝습니다.

## 실행 방법

```bash
cd labs/lab-08-metadata-operations
./run.sh
./validate_all.sh
```

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark** | ● **`expire_snapshots`** (CALL 또는 Lab SQL 방식) | — |
| **Hive / Impala** | ○ 정리 **후** 테이블 **SELECT/COUNT** 로 정상 조회 | — |

## 선행 Lab

**Lab 04** — MERGE 등으로 **스냅샷이 여러 개** 있는 상태가 있으면 expire 전·후 차이를 이해하기 쉽습니다.

## 다음 Lab

**Lab 09** — 지금까지 배운 것을 **한 테이블을 Spark·Hive·Impala가 같이 쓰는** 관점에서 정리합니다.
