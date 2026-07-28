# Lab × 엔진 매트릭스

| Lab | Spark | Hive | Impala | validate 3엔진 |
|-----|-------|------|--------|----------------|
| 01 | CREATE, INSERT | INSERT | SELECT | COUNT |
| 02 | PARTITION DDL | SELECT | EXPLAIN | COUNT |
| 03 | ALTER | SELECT | REFRESH+SELECT | COUNT |
| 04 | MERGE | SELECT | COUNT | COUNT |
| 05 | tag, snapshots | FOR SYSTEM_TIME | COUNT | COUNT |
| 06 | MoR props, UPDATE | SELECT | UPDATE | COUNT |
| 07 | rewrite_data_files | — | — | COUNT |
| 08 | expire_snapshots | SELECT | SELECT | COUNT |
| 09 | engine label SELECT | 동일 | 동일 | COUNT |
| 10 | DESCRIBE EXTENDED | DESCRIBE | DESCRIBE | COUNT |
| 11 | SELECT 1 | SELECT 1 | SELECT 1 | ok |
| 12 | COUNT | COUNT | COUNT | COUNT |
| 13 | COUNT (HMS) | COUNT | COUNT | COUNT |

● = 실습 SQL, ○ = 검증 위주. Maintenance(07–08)는 Spark 후 Hive/Impala read 검증.
