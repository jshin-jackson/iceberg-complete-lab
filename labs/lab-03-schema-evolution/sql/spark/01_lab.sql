-- 01_lab.sql
USE iceberg_lab;
ALTER TABLE customers ADD COLUMNS (loyalty_tier STRING);
UPDATE customers SET loyalty_tier = 'GOLD' WHERE customer_id = 1;
ALTER TABLE customers RENAME COLUMN loyalty_tier TO tier;
SELECT customer_id, tier FROM customers WHERE tier IS NOT NULL LIMIT 5;
