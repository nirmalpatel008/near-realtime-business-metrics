-- Portfolio demo seed: synthetic finance/product analytics data.
-- Run against SOURCE before starting the DMS task.
--
-- This script creates a richer schema than the original Summit demo:
-- regions, customers, accounts, merchants, devices, transactions, payments,
-- and product events. It intentionally uses synthetic data only.

USE demo;

SET SESSION cte_max_recursion_depth = 20000;

DROP TABLE IF EXISTS user_events;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS devices;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS merchants;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS regions;

CREATE TABLE regions (
  region_id    INT PRIMARY KEY AUTO_INCREMENT,
  country      VARCHAR(64) NOT NULL,
  state        VARCHAR(64) NOT NULL,
  city         VARCHAR(64) NOT NULL,
  timezone     VARCHAR(64) NOT NULL
);

CREATE TABLE customers (
  customer_id       INT PRIMARY KEY AUTO_INCREMENT,
  full_name         VARCHAR(128) NOT NULL,
  email_hash        CHAR(64) NOT NULL,
  customer_segment  VARCHAR(32) NOT NULL,
  signup_ts         DATETIME(6) NOT NULL,
  region_id         INT NOT NULL,
  kyc_status        VARCHAR(32) NOT NULL,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  INDEX (region_id),
  INDEX (signup_ts)
);

CREATE TABLE accounts (
  account_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id   INT NOT NULL,
  account_type  VARCHAR(32) NOT NULL,
  balance       DECIMAL(12,2) NOT NULL,
  currency      CHAR(3) NOT NULL DEFAULT 'INR',
  opened_ts     DATETIME(6) NOT NULL,
  status        VARCHAR(32) NOT NULL,
  INDEX (customer_id),
  INDEX (opened_ts)
);

CREATE TABLE merchants (
  merchant_id        INT PRIMARY KEY AUTO_INCREMENT,
  merchant_name      VARCHAR(128) NOT NULL,
  merchant_category  VARCHAR(64) NOT NULL,
  region_id          INT NOT NULL,
  risk_tier          VARCHAR(16) NOT NULL,
  created_ts         DATETIME(6) NOT NULL,
  INDEX (region_id),
  INDEX (merchant_category)
);

CREATE TABLE devices (
  device_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id    INT NOT NULL,
  device_type    VARCHAR(32) NOT NULL,
  os             VARCHAR(32) NOT NULL,
  app_version    VARCHAR(32),
  browser        VARCHAR(64),
  first_seen_ts  DATETIME(6) NOT NULL,
  INDEX (customer_id),
  INDEX (device_type),
  INDEX (os)
);

CREATE TABLE transactions (
  transaction_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id         INT NOT NULL,
  merchant_id         INT NOT NULL,
  amount              DECIMAL(12,2) NOT NULL,
  currency            CHAR(3) NOT NULL DEFAULT 'INR',
  transaction_status  VARCHAR(32) NOT NULL,
  channel             VARCHAR(32) NOT NULL,
  event_ts            DATETIME(6) NOT NULL,
  created_ts          DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  INDEX (customer_id),
  INDEX (merchant_id),
  INDEX (transaction_status),
  INDEX (event_ts)
);

CREATE TABLE payments (
  payment_id            BIGINT PRIMARY KEY AUTO_INCREMENT,
  transaction_id        BIGINT NOT NULL,
  customer_id           INT NOT NULL,
  payment_method        VARCHAR(32) NOT NULL,
  payment_status        VARCHAR(32) NOT NULL,
  failure_reason        VARCHAR(64),
  processor_latency_ms  INT,
  event_ts              DATETIME(6) NOT NULL,
  INDEX (transaction_id),
  INDEX (customer_id),
  INDEX (payment_status),
  INDEX (event_ts)
);

CREATE TABLE user_events (
  event_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id     INT NOT NULL,
  session_id      VARCHAR(64) NOT NULL,
  device_id       BIGINT,
  event_type      VARCHAR(64) NOT NULL,
  merchant_id     INT,
  transaction_id  BIGINT,
  event_ts        DATETIME(6) NOT NULL,
  metadata_json   JSON,
  INDEX (customer_id),
  INDEX (session_id),
  INDEX (event_type),
  INDEX (event_ts)
);

INSERT INTO regions (country, state, city, timezone) VALUES
  ('India', 'Karnataka', 'Bengaluru', 'Asia/Kolkata'),
  ('India', 'Maharashtra', 'Mumbai', 'Asia/Kolkata'),
  ('India', 'Delhi', 'Delhi', 'Asia/Kolkata'),
  ('India', 'Tamil Nadu', 'Chennai', 'Asia/Kolkata'),
  ('India', 'Telangana', 'Hyderabad', 'Asia/Kolkata'),
  ('India', 'Gujarat', 'Ahmedabad', 'Asia/Kolkata'),
  ('India', 'West Bengal', 'Kolkata', 'Asia/Kolkata'),
  ('India', 'Rajasthan', 'Jaipur', 'Asia/Kolkata');

INSERT INTO customers (full_name, email_hash, customer_segment, signup_ts, region_id, kyc_status, is_active)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 1000
)
SELECT
  CONCAT('Customer_', n),
  SHA2(CONCAT('customer_', n, '@example.invalid'), 256),
  ELT(1 + (n % 4), 'mass', 'premium', 'student', 'small_business'),
  NOW(6) - INTERVAL (n % 180) DAY,
  1 + (n % 8),
  ELT(1 + (n % 3), 'VERIFIED', 'PENDING', 'REVIEW'),
  n % 20 <> 0
FROM seq;

INSERT INTO accounts (customer_id, account_type, balance, currency, opened_ts, status)
SELECT
  customer_id,
  ELT(1 + (customer_id % 3), 'wallet', 'savings', 'credit'),
  ROUND(1000 + RAND(customer_id) * 99000, 2),
  'INR',
  signup_ts + INTERVAL 1 HOUR,
  CASE WHEN is_active THEN 'ACTIVE' ELSE 'DORMANT' END
FROM customers;

INSERT INTO merchants (merchant_name, merchant_category, region_id, risk_tier, created_ts)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 200
)
SELECT
  CONCAT('Merchant_', n),
  ELT(1 + (n % 6), 'grocery', 'travel', 'food_delivery', 'electronics', 'education', 'utilities'),
  1 + (n % 8),
  ELT(1 + (n % 3), 'low', 'medium', 'high'),
  NOW(6) - INTERVAL (n % 365) DAY
FROM seq;

INSERT INTO devices (customer_id, device_type, os, app_version, browser, first_seen_ts)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 1200
)
SELECT
  1 + (n % 1000),
  ELT(1 + (n % 3), 'mobile', 'web', 'tablet'),
  ELT(1 + (n % 4), 'Android', 'iOS', 'Windows', 'macOS'),
  CONCAT('2026.', 1 + (n % 5), '.', n % 10),
  ELT(1 + (n % 4), 'Chrome', 'Safari', 'Edge', 'Firefox'),
  NOW(6) - INTERVAL (n % 120) DAY
FROM seq;

INSERT INTO transactions (customer_id, merchant_id, amount, currency, transaction_status, channel, event_ts, created_ts)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 5000
)
SELECT
  1 + (n % 1000),
  1 + (n % 200),
  ROUND(50 + RAND(n) * 25000, 2),
  'INR',
  CASE
    WHEN n % 20 = 0 THEN 'FAILED'
    WHEN n % 17 = 0 THEN 'REFUNDED'
    ELSE 'COMPLETED'
  END,
  ELT(1 + (n % 3), 'mobile_app', 'web', 'partner_api'),
  NOW(6) - INTERVAL (5000 - n) SECOND,
  NOW(6) - INTERVAL (5000 - n) SECOND
FROM seq;

INSERT INTO payments (transaction_id, customer_id, payment_method, payment_status, failure_reason, processor_latency_ms, event_ts)
SELECT
  transaction_id,
  customer_id,
  ELT(1 + (transaction_id % 5), 'upi', 'card', 'netbanking', 'wallet', 'bnpl'),
  CASE WHEN transaction_status = 'FAILED' THEN 'FAILED' ELSE 'SUCCESS' END,
  CASE
    WHEN transaction_status <> 'FAILED' THEN NULL
    ELSE ELT(1 + (transaction_id % 5), 'INSUFFICIENT_FUNDS', 'BANK_TIMEOUT', 'RISK_DECLINED', 'INVALID_METHOD', 'NETWORK_ERROR')
  END,
  80 + (transaction_id % 900),
  event_ts + INTERVAL 100000 MICROSECOND
FROM transactions;

INSERT INTO user_events (customer_id, session_id, device_id, event_type, merchant_id, transaction_id, event_ts, metadata_json)
SELECT
  t.customer_id,
  CONCAT('sess_', t.customer_id, '_', FLOOR(t.transaction_id / 5)),
  1 + (t.customer_id % 1200),
  e.event_type,
  t.merchant_id,
  CASE WHEN e.event_type IN ('payment_initiated', 'payment_success', 'payment_failed', 'purchase_completed') THEN t.transaction_id ELSE NULL END,
  t.event_ts + INTERVAL e.step_offset SECOND,
  JSON_OBJECT('channel', t.channel, 'synthetic', true)
FROM transactions t
JOIN (
  SELECT 'login' AS event_type, -4 AS step_offset
  UNION ALL SELECT 'view_merchant', -3
  UNION ALL SELECT 'payment_initiated', -2
  UNION ALL SELECT 'payment_success', -1
  UNION ALL SELECT 'purchase_completed', 0
) e
WHERE t.transaction_status IN ('COMPLETED', 'REFUNDED')
UNION ALL
SELECT
  t.customer_id,
  CONCAT('sess_', t.customer_id, '_', FLOOR(t.transaction_id / 5)),
  1 + (t.customer_id % 1200),
  e.event_type,
  t.merchant_id,
  CASE WHEN e.event_type IN ('payment_initiated', 'payment_failed') THEN t.transaction_id ELSE NULL END,
  t.event_ts + INTERVAL e.step_offset SECOND,
  JSON_OBJECT('channel', t.channel, 'synthetic', true)
FROM transactions t
JOIN (
  SELECT 'login' AS event_type, -4 AS step_offset
  UNION ALL SELECT 'view_merchant', -3
  UNION ALL SELECT 'payment_initiated', -2
  UNION ALL SELECT 'payment_failed', -1
) e
WHERE t.transaction_status = 'FAILED';

SELECT 'regions' AS table_name, COUNT(*) AS rows_ FROM regions
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL SELECT 'merchants', COUNT(*) FROM merchants
UNION ALL SELECT 'devices', COUNT(*) FROM devices
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'user_events', COUNT(*) FROM user_events;
