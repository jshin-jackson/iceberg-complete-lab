# Lab 09 — Multi-Engine (여러 엔진, 하나의 테이블)

**트랙:** Core (Core 트랙 마무리)  
**난이도:** 초급 (개념 정리)

## 이 Lab에서 배우는 것

Lakehouse·Iceberg의 큰 장점 중 하나는 **저장 형식은 하나(Iceberg), SQL 엔진은 여러 개**라는 점입니다.

- **Spark**: ETL, MERGE, compaction, maintenance procedure
- **Hive**: 배치 SQL, 레거시 파이프라인
- **Impala**: 대화형 **빠른 SELECT**

모두 **같은 HMS에 등록된 같은 Iceberg 테이블**을 보면, “Spark로 넣은 데이터를 Impala에서 바로 조회” 같은 워크플로가 가능합니다 (캐시·REFRESH 타이밍은 엔진마다 주의).

이 Lab은 새로운 Iceberg 기능보다 **3엔진 동시 사용**을 **의도적으로 연습**합니다.

## 실행 방법

```bash
cd labs/lab-09-multi-engine
./run.sh
./validate_all.sh
```

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark** | ● **SELECT** | validate 스크립트 |
| **Hive** | ● **SELECT** | validate 스크립트 |
| **Impala** | ● **SELECT** | validate 스크립트 |

**목표:** 동일 테이블에 대해 세 엔진의 **COUNT·샘플 조회**가 서로 모순되지 않음을 확인합니다.

## 선행 Lab

**Lab 01** — 공통 DB·테이블·warehouse가 준비되어 있어야 합니다. Core Lab 02~08을 거쳤다면 이 Lab이 더 쉽게 느껴집니다.

## 다음 Lab (Appendix)

**Lab 10** — CDP에서 자주 쓰는 **Ozone(`ofs://`) warehouse 경로**를 DESCRIBE·COUNT로 확인합니다.
