# Iceberg 기능 개요

| 기능 | 설명 | Lab |
|------|------|-----|
| ACID | Snapshot 단위 일관성 | 04 |
| Hidden partitioning | 소스 컬럼과 파티션 분리 | 02 |
| Schema evolution | ALTER without rewrite | 03 |
| Time travel | 과거 snapshot 조회 | 05 |
| MoR / CoW | delete/update 방식 | 06 |
| Compaction | rewrite data files | 07 |
| Maintenance | expire snapshots | 08 |

Spark: `TIMESTAMP AS OF` / Hive·Impala: `FOR SYSTEM_TIME AS OF`
