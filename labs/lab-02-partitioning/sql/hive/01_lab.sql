-- 01_lab.sql
USE iceberg_lab;
SELECT COUNT(*) FROM orders_part WHERE order_date >= '2024-02-01';
