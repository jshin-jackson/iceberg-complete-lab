# 트러블슈팅

1. **kinit 실패** — keytab 경로 `/cdep/keytabs/systest.keytab`, principal 대소문자 확인
2. **ofs 접근 거부 / warehouse 없음** — volume·bucket·warehouse: [`04-ozone-storage.md`](04-ozone-storage.md) §1; **Ranger 거부** — 같은 문서 **§3** (`cm_ozone` Audits, user·key prefix), `./scripts/setup_ozone_storage.sh --check`
3. **Beeline 연결 실패** — `HIVESERVER2_LOAD_BALANCER` **`host:10015`**, `HIVE_SERVER2_PRINCIPAL=hive/<동일 FQDN>@REALM`, SSL truststore: [`03-cloudera-integration.md`](03-cloudera-integration.md) Beeline 절; `kinit` 선행
4. **Impala 연결 실패** — `.env`: coordinator **`host:25003`** (21000 아님), `IMPALA_SSL=true`, `IMPALA_CA_CERT` (CM `cm-auto-global_cacerts.pem`), `kinit` 후 [`03-cloudera-integration.md`](03-cloudera-integration.md) Impala 절
5. **Impala 테이블 없음** — `INVALIDATE METADATA` / `REFRESH db.table`
6. **Spark catalog not found** — `ICEBERG_CATALOG=hive_prod`, extensions 설정
7. **MERGE Hive 실패** — Spark에서 MERGE 후 Hive는 SELECT만
8. **Impala UPDATE 제한** — MoR, Parquet only; equality delete 미지원
9. **Time travel 빈 결과** — snapshot 이전 시각이 데이터 없을 수 있음
10. **CALL system.* 실패** — Spark 3 + Iceberg extensions, fully qualified `hive_prod.db.table`
11. **COUNT 불일치** — Lab 순서(01→…) 지키고 동일 `iceberg_lab` DB 사용
12. **Kerberos ticket 만료** — `kinit -kt ...` 재실행
13. **warehouse REPLACE** — `.env`의 `WAREHOUSE_OFS` 실제 vol/bucket으로 변경
