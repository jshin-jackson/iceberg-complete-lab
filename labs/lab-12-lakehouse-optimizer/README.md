# Lab 12 — Lakehouse Optimizer (Appendix)

**트랙:** Appendix (CDP·운영)  
**난이도:** 초급 (UI·개념 관찰)

## 이 Lab에서 배우는 것

**Lab 07**에서는 Spark **`rewrite_data_files`** 로 **수동 compaction**을 실행했습니다.

Cloudera CDP에는 **Lakehouse Optimizer**(Cloudera Manager UI)가 있어, Iceberg 테이블에 대해:

- 작은 파일 병합
- (정책에 따라) snapshot·delete file 관련 유지보수

등을 **자동·스케줄**로 돕는 경우가 있습니다.

이 Lab은 SQL로 새 Iceberg 기능을 배우기보다:

1. Optimizer **화면/정책**에서 대상 테이블·작업 상태를 **관찰**하고
2. **3엔진 COUNT** 등으로 **데이터는 여전히 일관되게 읽히는지** 확인합니다.

**비교 정리**

| | Lab 07 (수동) | Lab 12 (Optimizer) |
|---|----------------|---------------------|
| 실행 주체 | 개발자가 Spark CALL | CM 정책·서비스 |
| 학습 목표 | Iceberg procedure 이해 | 운영 자동화 개념 |

## 실행 방법

```bash
cd labs/lab-12-lakehouse-optimizer
./run.sh
./validate_all.sh
```

UI 단계는 Lab SQL·README 옆 안내 또는 `run.sh` 출력을 따릅니다. 클러스터에 Optimizer가 **미설치**면 UI 관찰은 건너뛰고 COUNT 검증만 할 수 있습니다.

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark / Hive / Impala** | Optimizer 동작 **관찰**(가능 시) + **COUNT** | 데이터 읽기 정상 |

## 선행 Lab

**Lab 07** — compaction이 무엇인지, 왜 필요한지를 먼저 아는 것이 좋습니다.

## 다음 Lab

**Lab 13** — **HMS 카탈로그** vs **REST Catalog** 개념과 데이터 공유 관점을 정리합니다.
