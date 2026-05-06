-- Draft schema for the portfolio version of the demo.
-- This is intentionally separate from scripts/01-seed-source.sql so the
-- original AWS Summit demo remains stable.

USE demo;

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
