# Lab 06 — Merge-on-Read vs Copy-on-Write (MoR / CoW)

**트랙:** Core  
**난이도:** 중급

## 이 Lab에서 배우는 것

Iceberg에서 **UPDATE·DELETE**는 “행 하나만 고치기”가 아니라 **Parquet 데이터 파일**과 **삭제/변경 마커**를 어떻게 다룰지의 문제입니다.

| 방식 | 짧은 설명 | 트레이드오프 |
|------|-----------|--------------|
| **Copy-on-Write (CoW)** | 변경 시 관련 **데이터 파일을 통째로 다시 씀** | 읽기는 단순·빠를 수 있음, 쓰기·컴팩션 부담 |
| **Merge-on-Read (MoR)** | 변경은 **별도 delete/position 파일** 등에 기록, 읽을 때 합침 | 쓰기는 가벼울 수 있음, 읽기·주기적 compaction 필요 |

Lab에서는 테이블 **속성(property)** 예: `write.delete.mode`, `write.update.mode` 와 **UPDATE** SQL로 두 방식을 비교합니다.

## 실행 방법

```bash
cd labs/lab-06-merge-reads-writes
./run.sh
./validate_all.sh
```

## 3엔진 검증

| 엔진 | 이 Lab에서 하는 일 | 검증 |
|------|-------------------|------|
| **Spark** | ● 테이블 **properties** 설정, **UPDATE** | — |
| **Impala** | ● (Lab 구성에 따라) **MoR** 테이블 **UPDATE** | — |
| **Hive** | ○ 결과 **SELECT** | — |

엔진·버전에 따라 UPDATE 지원 범위가 다릅니다. Lab SQL이 “어디서 쓰고 어디서 읽는지” 기준입니다.

## 선행 Lab

**Lab 01** — 기본 Iceberg 테이블·DB.

## 다음 Lab

**Lab 07** — MoR 등으로 **작은 파일·delete 파일**이 많아졌을 때 **compaction**(`rewrite_data_files`)으로 읽기 성능을 되살립니다. Lab 06의 `mor_demo`를 선행으로 둡니다.
