# KPI Definitions

This document defines the business metrics used by the dashboard, tutorials, and query runner.

## Daily Active Users

**Question:** How many unique customers were active each day?

**Grain:** one row per day, optionally segmented by region, device, or customer segment.

**Definition:**

```text
COUNT(DISTINCT customer_id)
WHERE event_type IN ('login', 'payment_initiated', 'purchase_completed')
GROUP BY DATE(event_ts)
```

## Conversion Rate

**Question:** What share of active sessions became completed purchases?

**Grain:** one row per day, optionally segmented by region, device, or merchant category.

**Definition:**

```text
purchase_completed users / login users
```

For a stricter funnel, use sessions instead of users:

```text
sessions with purchase_completed / sessions with login
```

## Payment Success Rate

**Question:** How reliable is payment processing?

**Grain:** one row per day, optionally segmented by region, payment method, device, or failure reason.

**Definition:**

```text
successful payments / total payment attempts
```

## Funnel Analysis

**Question:** Where do users drop off?

**Recommended funnel:**

```text
login
-> view_merchant
-> payment_initiated
-> payment_success
-> purchase_completed
```

Each step should count distinct sessions or distinct customers. Use sessions for product analytics and customers for executive summaries.

## Time-Series Trends

**Question:** Are metrics moving up or down?

Track daily values for:

- DAU
- transactions
- gross transaction value
- payment success rate
- conversion rate
- failed payments

Useful comparison windows:

- day over day
- trailing 7 days
- trailing 30 days

## Geographic Segmentation

**Question:** Which cities or regions are growing, failing, or converting poorly?

Useful cuts:

- DAU by city
- payment success rate by city
- gross transaction value by region
- failed payment reasons by region

## Device Segmentation

**Question:** Are mobile, web, OS, or app-version issues hurting conversion?

Useful cuts:

- conversion rate by device type
- payment success rate by OS
- failed payments by app version
- DAU by mobile versus web

## Dashboard Freshness

**Question:** How current is the dashboard?

**Definition:**

```text
NOW() - MAX(event_ts)
```

Track freshness both at the raw replication layer and at the final dashboard layer.
