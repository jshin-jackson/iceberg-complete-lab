-- 01_lab.sql
USE iceberg_lab;
UPDATE mor_demo SET val = 'impala' WHERE id = 2;
SELECT * FROM mor_demo ORDER BY id;
