-- 01_lab.sql
USE iceberg_lab;
INSERT INTO merge_demo VALUES (3, 'v3');
SELECT * FROM merge_demo;
SELECT snapshot_id, committed_at FROM iceberg_lab.merge_demo.snapshots ORDER BY committed_at DESC LIMIT 3;
CREATE TAG IF NOT EXISTS tag_lab05 ON TABLE merge_demo;
