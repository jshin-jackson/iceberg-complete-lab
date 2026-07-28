# Lab 04 — ACID 트랜잭션 & MERGE

**트랙:** Core  
**난이도:** 초급~중급

## 이 Lab에서 배우는 것

### ACID가 여기서 의미하는 것

데이터 레이크에서 “동시에 두 job이 같은 파일을 덮어쓰면?” 문제가 납니다. Iceberg는 **커밋 단위로 새 스냅샷**을 만들어, 읽기는 **일관된 스냅샷**만 보도록 합니다. 그래서 **원자적(atomic) 커밋**에 가까운 동작을 기대할 수 있습니다.

### MERGE INTO

운영에서 자주 쓰는 패턴입니다.

- 소스(스테이징)와 타겟(본 테이블)을 **한 SQL**로 비교
- 있으면 **UPDATE**, 없으면 **INSERT** (Lab SQL에 맞게 WHEN 절 구성)

이 Lab에서는 MERGE 후 **스냅샷(snapshots)이 늘어나는 것**도 확인합니다. 스냅샷 = “그 시점의 테이블 전체 상태” 기록.

## 실행 방법

```bash
cd labs/lab-04-acid-transactions
./run.sh
./validate_all.sh
```

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark** | ● **MERGE INTO** (쓰기·고급 DML) | — |
| **Hive / Impala** | ○ MERGE 결과 **SELECT** | 행 수·내용 일치 |

MERGE는 주로 **Spark**에서 실행하는 경우가 많고, Hive/Impala는 **결과 읽기**로 검증하는 구성입니다.

## 선행 Lab

**Lab 01** — MERGE 대상 테이블·DB가 준비되어 있어야 합니다.

## 다음 Lab

**Lab 05** — MERGE로 쌓인 **과거 스냅샷**을 이용해 **Time Travel**(특정 시점 데이터 조회)과 **tag/branch** 개념을 배웁니다. Lab 04의 `merge_demo` 관련 객체를 선행으로 언급합니다.
