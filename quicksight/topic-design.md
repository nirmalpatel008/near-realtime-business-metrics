# QuickSight Topic Design

Topic name:

```text
Business Metrics Pipeline
```

## Purpose

Enable business users to ask questions about synthetic near real-time product and payment metrics.

## Included Subject Areas

- active users
- conversion
- funnel
- payments
- failures
- geography
- devices
- freshness

## Recommended Datasets

For the first version, build topics on curated KPI datasets or database views rather than raw transactional tables.

Recommended datasets:

- `kpi_daily_metrics`
- `funnel_daily`
- `payment_reliability`
- `geo_device_segments`
- `data_freshness`

## Field Descriptions

| Field | Description |
|---|---|
| `metric_date` | Date of the metric |
| `daily_active_users` | Number of unique active customers |
| `login_users` | Unique users who logged in |
| `converted_users` | Unique users who completed a purchase |
| `conversion_rate_pct` | Percentage of login users who completed a purchase |
| `payment_attempts` | Count of attempted payments |
| `successful_payments` | Count of successful payments |
| `success_rate_pct` | Percentage of payment attempts that succeeded |
| `failure_reason` | Reason a payment failed |
| `city` | Customer city |
| `device_type` | Device class such as mobile, web, or tablet |
| `os` | Operating system |
| `freshness_sec` | Seconds since the latest replicated event |

## Synonyms

| Field | Synonyms |
|---|---|
| `daily_active_users` | DAU, active users |
| `conversion_rate_pct` | conversion, purchase conversion |
| `success_rate_pct` | payment success, payment reliability |
| `payment_attempts` | attempted payments |
| `failure_reason` | error reason, failure cause |
| `freshness_sec` | lag, delay, data freshness |

## Named Entities

Suggested values:

- device types: `mobile`, `web`, `tablet`
- operating systems: `Android`, `iOS`, `Windows`, `macOS`
- payment methods: `upi`, `card`, `netbanking`, `wallet`, `bnpl`
- cities: `Bengaluru`, `Mumbai`, `Delhi`, `Chennai`, `Hyderabad`, `Ahmedabad`, `Kolkata`, `Jaipur`

## Guardrails

Do not expose:

- raw `email_hash`
- internal row IDs unless needed for debugging
- uncurated JSON metadata

Prefer curated metrics over raw event tables for questions.

## Validation Questions

Use these after creating the topic:

- What was DAU yesterday?
- Show conversion rate by day.
- Which city has the lowest payment success rate?
- Show payment failures by reason.
- How fresh is the dashboard?
- Compare conversion by device type.
