# Synthetic Data Model

The expanded project uses synthetic finance-domain data. The data should feel realistic enough for workshops and dashboards, but it must never include real customer or production records.

## Source Tables

### `customers`

One row per synthetic user.

Recommended columns:

- `customer_id`
- `full_name`
- `email_hash`
- `customer_segment`
- `signup_ts`
- `region_id`
- `primary_device_id`
- `kyc_status`
- `is_active`

### `accounts`

One or more accounts per customer.

Recommended columns:

- `account_id`
- `customer_id`
- `account_type`
- `balance`
- `currency`
- `opened_ts`
- `status`

### `merchants`

Synthetic merchant directory.

Recommended columns:

- `merchant_id`
- `merchant_name`
- `merchant_category`
- `region_id`
- `risk_tier`
- `created_ts`

### `transactions`

Commercial transaction intent and purchase records.

Recommended columns:

- `transaction_id`
- `customer_id`
- `merchant_id`
- `amount`
- `currency`
- `transaction_status`
- `channel`
- `event_ts`
- `created_ts`

Suggested statuses:

- `INITIATED`
- `AUTHORIZED`
- `COMPLETED`
- `FAILED`
- `REFUNDED`

### `payments`

Payment attempts associated with transactions.

Recommended columns:

- `payment_id`
- `transaction_id`
- `customer_id`
- `payment_method`
- `payment_status`
- `failure_reason`
- `processor_latency_ms`
- `event_ts`

Suggested statuses:

- `SUCCESS`
- `FAILED`
- `PENDING`

Suggested failure reasons:

- `INSUFFICIENT_FUNDS`
- `BANK_TIMEOUT`
- `RISK_DECLINED`
- `INVALID_METHOD`
- `NETWORK_ERROR`

### `user_events`

Product activity events for funnel and DAU metrics.

Recommended columns:

- `event_id`
- `customer_id`
- `session_id`
- `device_id`
- `event_type`
- `merchant_id`
- `transaction_id`
- `event_ts`
- `metadata_json`

Suggested event types:

- `login`
- `view_home`
- `view_merchant`
- `add_payment_method`
- `payment_initiated`
- `payment_success`
- `payment_failed`
- `purchase_completed`
- `logout`

### `devices`

Device and app metadata.

Recommended columns:

- `device_id`
- `customer_id`
- `device_type`
- `os`
- `app_version`
- `browser`
- `first_seen_ts`

### `regions`

Geography metadata.

Recommended columns:

- `region_id`
- `country`
- `state`
- `city`
- `timezone`

## Analytics Model

Use a simple star schema.

Dimensions:

- `dim_customer`
- `dim_device`
- `dim_region`
- `dim_merchant`

Facts:

- `fact_transactions`
- `fact_payments`
- `fact_user_events`

KPI tables or views:

- `kpi_daily_active_users`
- `kpi_conversion_rate_daily`
- `kpi_payment_success_daily`
- `kpi_funnel_daily`
- `kpi_geo_daily`
- `kpi_device_daily`

## Timestamp Strategy

Every event-like table should include an event timestamp from the source system:

- `event_ts`: when the business event happened
- `created_ts`: when the row was created in the source database
- target query time: when the analytics target sees the row

This enables near real-time freshness and lag demos.
