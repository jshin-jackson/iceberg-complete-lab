-- 01_lab.sql
USE iceberg_lab;
REFRESH customers;
SELECT customer_id, tier FROM customers LIMIT 5;
