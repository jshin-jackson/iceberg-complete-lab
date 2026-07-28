-- 01_lab.sql
USE iceberg_lab;
CREATE TABLE IF NOT EXISTS mor_demo (id INT, val STRING) USING iceberg
TBLPROPERTIES ('write.delete.mode'='merge-on-read', 'write.update.mode'='merge-on-read');
INSERT INTO mor_demo VALUES (1, 'a'), (2, 'b');
UPDATE mor_demo SET val = 'updated' WHERE id = 1;
SELECT * FROM mor_demo ORDER BY id;
