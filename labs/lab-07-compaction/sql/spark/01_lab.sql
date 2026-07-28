-- 01_lab.sql
USE iceberg_lab;
CALL hive_prod.system.rewrite_data_files(table => 'iceberg_lab.mor_demo');
SELECT COUNT(*) FROM mor_demo;
