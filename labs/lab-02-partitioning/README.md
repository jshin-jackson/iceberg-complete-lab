# Lab 02 — Hidden Partitioning (숨은 파티션)

**트랙:** Core  
**난이도:** 입문~초급

## 이 Lab에서 배우는 것

**파티션**은 데이터를 폴더/파일 단위로 나누어, “특정 날짜·지역만 읽기”처럼 **스캔 범위를 줄이는** 방법입니다.

Hive 스타일 파티션은 보통 `WHERE order_date='2024-01-01'`처럼 **파티션 컬럼을 쿼리에 직접 써야** 잘 동작합니다.  
Iceberg **Hidden Partitioning**은:

- 테이블 정의 시 `days(주문일)`, `bucket(고객 id, 16)` 같은 **변환 함수**로 파티션 규칙을 정하고
- 사용자는 **원본 컬럼**(`order_date`, `customer_id`)만으로 필터해도
- Iceberg가 알아서 **맞는 파티션만 읽도록** 최적화합니다.

이 Lab에서 다루는 키워드: `partition spec`, `days()`, `bucket()`.

## 왜 중요한가요?

데이터가 커질수록 “전체 파일 읽기”는 느립니다. 파티션·파일 통계를 Iceberg가 관리하므로, 엔진(Spark/Hive/Impala)이 **덜 읽고** 같은 결과를 낼 수 있습니다.

## 실행 방법

```bash
cd labs/lab-02-partitioning
./run.sh
./validate_all.sh
```

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark** | ● 파티션 spec이 포함된 **DDL**(테이블 생성·변경) | — |
| **Hive / Impala** | ○ **EXPLAIN** 또는 **SELECT**로 실행 계획·결과 확인 | 파티션 pruning이 기대대로인지 관찰 |

● = DDL 주로 Spark, ○ = 읽기·계획 확인

## 선행 Lab

**Lab 01** — Iceberg DB·warehouse·기본 테이블 개념을 이미 다루었는지 확인하세요.

## 다음 Lab

**Lab 03** — 컬럼 추가·이름 변경 등 **스키마를 바꿔도** 데이터 파일 전체를 다시 쓰지 않는 **schema evolution**을 배웁니다.
