# 트러블슈팅

1. **kinit 실패** — keytab 경로 `/cdep/keytabs/systest.keytab`, principal 대소문자 확인
2. **ofs 접근 거부** — Ozone volume/bucket `.env` 수정, Ranger Ozone 정책
3. **Beeline 연결 실패** — `HIVE_SERVER2_JDBC` principal `hive/_HOST@REALM`
4. **Impala 테이블 없음** — `INVALIDATE METADATA` / `REFRESH db.table`
5. **Spark catalog not found** — `ICEBERG_CATALOG=hive_prod`, extensions 설정
6. **MERGE Hive 실패** — Spark에서 MERGE 후 Hive는 SELECT만
7. **Impala UPDATE 제한** — MoR, Parquet only; equality delete 미지원
8. **Time travel 빈 결과** — snapshot 이전 시각이 데이터 없을 수 있음
9. **CALL system.* 실패** — Spark 3 + Iceberg extensions, fully qualified `hive_prod.db.table`
10. **COUNT 불일치** — Lab 순서(01→…) 지키고 동일 `iceberg_lab` DB 사용
11. **Kerberos ticket 만료** — `kinit -kt ...` 재실행
12. **warehouse REPLACE** — `.env`의 `WAREHOUSE_OFS` 실제 vol/bucket으로 변경
