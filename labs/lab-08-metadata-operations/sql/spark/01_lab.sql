-- 01_lab.sql
USE iceberg_lab;
CALL hive_prod.system.expire_snapshots(table => 'iceberg_lab.merge_demo', older_than => TIMESTAMP '2099-01-01 00:00:00', retain_last => 1);
SELECT COUNT(*) FROM iceberg_lab.merge_demo.snapshots;
