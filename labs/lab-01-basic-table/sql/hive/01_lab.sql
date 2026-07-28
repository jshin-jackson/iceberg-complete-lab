-- 01_lab.sql
USE iceberg_lab;
INSERT INTO customers VALUES (3, 'Carol', 'c@ex.com', '2022-01-01', 'JP', 25, 'F', false);
SELECT COUNT(*) AS cnt FROM customers;
