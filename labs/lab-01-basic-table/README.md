# Lab 01 — Iceberg 테이블 기본

**트랙:** Core (필수 첫 Lab)  
**난이도:** 입문

## 이 Lab에서 배우는 것

Iceberg 테이블을 **처음부터** 만드는 전체 흐름을 익힙니다.

1. **CREATE TABLE** — Iceberg 형식으로 테이블 정의
2. **INSERT** — 데이터 넣기
3. **CRUD** — 조회·수정·삭제에 가까운 기본 SQL (엔진별 지원 범위는 Lab SQL 주석 참고)
4. **시스템 테이블** — Iceberg가 관리하는 메타데이터(스냅샷, 파일 목록 등)를 SQL로 peek
5. **warehouse** — 데이터 파일이 실제로 저장되는 Ozone 경로(`ofs://...`) 이해

일반 Hive 외부 테이블과 비슷해 보여도, Iceberg는 **스냅샷·메타데이터 레이어**가 있어 이후 Lab(시간 여행, MERGE 등)의 기반이 됩니다.

## 실행 전 준비

1. 프로젝트 루트에서 `.env` 설정 (HMS, HiveServer2, Impala, Ozone warehouse)
2. Kerberos가 필요한 클러스터면 `kinit` 등으로 로그인
3. (데이터 Lab) `synthetic-data`로 고객·주문 Parquet 생성 — Lab SQL/README 상단 안내 확인

## 실행 방법

```bash
cd labs/lab-01-basic-table
./run.sh              # Spark 등으로 실습 SQL 실행
./validate_all.sh     # Spark + Hive + Impala에서 결과 확인
```

`run.sh`가 실패하면 `labs/common/env.sh`가 `.env`를 읽는지, 호스트·principal이 맞는지 확인하세요.

## 3엔진 검증이란?

같은 Iceberg 테이블을 **세 가지 SQL 엔진**으로 읽어 보며 “한 테이블, 여러 도구”를 확인합니다.

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark** | ● CREATE, INSERT 등 **쓰기·DDL** 위주 | COUNT 등 |
| **Hive** | ● INSERT (Lab SQL 기준) | COUNT |
| **Impala** | ○ **SELECT** 위주 (Impala는 REFRESH 후 조회하는 경우 많음) | COUNT |

● = 이 Lab SQL에서 적극 사용, ○ = 읽기·검증 위주

**목표:** 세 엔진 모두에서 **행 개수(COUNT)** 가 일치하는지 `validate_all.sh`로 확인합니다.

## 다음 Lab

**Lab 02 (파티션)** — 데이터를 나누어 저장하는 “hidden partitioning”을 배웁니다. Lab 01에서 만든 테이블·DB(`iceberg_lab` 등)를 이어서 사용합니다.
