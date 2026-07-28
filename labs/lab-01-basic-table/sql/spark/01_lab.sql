-- 01_lab.sql
CREATE DATABASE IF NOT EXISTS iceberg_lab;
USE iceberg_lab;
CREATE TABLE IF NOT EXISTS customers (
  customer_id INT, name STRING, email STRING,
  registration_date TIMESTAMP, country STRING,
  age INT, gender STRING, vip_status BOOLEAN
) USING iceberg;
INSERT INTO customers VALUES
 (1, 'Alice', 'a@ex.com', timestamp '2021-01-01', 'KR', 30, 'F', true),
 (2, 'Bob', 'b@ex.com', timestamp '2021-06-01', 'US', 40, 'M', false);
SELECT * FROM customers;
SELECT * FROM customers.snapshots;
