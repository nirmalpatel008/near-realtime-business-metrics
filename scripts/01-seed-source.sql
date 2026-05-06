-- ACT 2 prep: seed source BEFORE starting DMS task.
-- Three tables demonstrate a realistic pipeline: customers, accounts, orders.
-- orders.event_ts (DATETIME(6) microsecond precision) is used to measure
-- true end-to-end replication lag (source commit -> target visible).

USE demo;

-- Raise recursive CTE limit so our 5k order generator doesn't truncate
SET SESSION cte_max_recursion_depth = 10000;

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
  id          INT PRIMARY KEY AUTO_INCREMENT,
  name        VARCHAR(100) NOT NULL,
  city        VARCHAR(50),
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
  id           INT PRIMARY KEY AUTO_INCREMENT,
  customer_id  INT NOT NULL,
  balance      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (customer_id)
);

CREATE TABLE orders (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  amount      DECIMAL(10,2) NOT NULL,
  status      VARCHAR(20) DEFAULT 'NEW',
  event_ts    DATETIME(6) NOT NULL,   -- microsecond source-commit marker
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX (customer_id),
  INDEX (event_ts)
);

-- 1,000 customers
INSERT INTO customers (name, city)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 1000
)
SELECT CONCAT('Customer_', n),
       ELT(1 + (n % 5), 'Bengaluru','Mumbai','Delhi','Chennai','Hyderabad')
FROM seq;

-- 1 account per customer
INSERT INTO accounts (customer_id, balance)
SELECT id, ROUND(10000 + RAND()*90000, 2) FROM customers;

-- 5,000 historical orders
INSERT INTO orders (customer_id, amount, status, event_ts)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 5000
)
SELECT 1 + (n % 1000),
       ROUND(100 + RAND()*9900, 2),
       ELT(1 + (n % 3), 'NEW','PAID','SHIPPED'),
       NOW(6)
FROM seq;

SELECT 'customers' AS t, COUNT(*) AS rows_ FROM customers
UNION ALL SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL SELECT 'orders',   COUNT(*) FROM orders;
