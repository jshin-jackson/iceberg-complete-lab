-- 01_lab.sql
USE iceberg_lab;
CREATE TABLE IF NOT EXISTS orders_part (
  order_id INT, customer_id INT, order_date TIMESTAMP, amount DOUBLE
) USING iceberg
PARTITIONED BY (days(order_date), bucket(16, customer_id));
INSERT INTO orders_part VALUES
 (1, 1, timestamp '2024-01-15 10:00:00', 99.9),
 (2, 2, timestamp '2024-02-20 11:00:00', 50.0);
EXPLAIN SELECT * FROM orders_part WHERE order_date >= '2024-02-01';
