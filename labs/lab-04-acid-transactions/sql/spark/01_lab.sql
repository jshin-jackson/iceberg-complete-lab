-- 01_lab.sql
USE iceberg_lab;
CREATE TABLE IF NOT EXISTS merge_demo (id INT, val STRING) USING iceberg;
INSERT INTO merge_demo VALUES (1, 'old'), (2, 'keep');
CREATE OR REPLACE TEMP VIEW upserts AS SELECT 1 AS id, 'new' AS val;
MERGE INTO merge_demo t USING upserts s ON t.id = s.id
 WHEN MATCHED THEN UPDATE SET val = s.val
 WHEN NOT MATCHED THEN INSERT *;
SELECT * FROM merge_demo ORDER BY id;
SELECT COUNT(*) FROM merge_demo.snapshots;
