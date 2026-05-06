# QuickSight Dashboard Spec

Dashboard name:

```text
Near Real-Time Business Metrics
```

## Audience

- product managers
- finance operations
- data engineering learners
- developer relations reviewers
- AWS/data engineering portfolio viewers

## Business Questions

The dashboard should answer:

- How many users are active today?
- Is conversion improving or dropping?
- Are payments healthy?
- Which cities or devices are underperforming?
- How fresh is the dashboard?
- Where should the team investigate next?

## Sheets

### 1. Executive Overview

Fields:

- `metric_date`
- `daily_active_users`
- `conversion_rate_pct`
- `success_rate_pct`
- `gross_transaction_value`
- `freshness_sec`

Visuals:

- KPI: DAU
- KPI: conversion rate
- KPI: payment success rate
- KPI: freshness
- line chart: DAU by date
- line chart: conversion rate by date
- line chart: payment success rate by date

### 2. Funnel Analysis

Fields:

- `metric_date`
- `login_sessions`
- `merchant_view_sessions`
- `payment_started_sessions`
- `payment_success_sessions`
- `purchase_sessions`

Visuals:

- funnel
- daily purchase trend
- daily step counts table

### 3. Payments Reliability

Fields:

- `metric_date`
- `payment_method`
- `payment_status`
- `failure_reason`
- `payment_attempts`
- `successful_payments`
- `success_rate_pct`

Visuals:

- payment success rate trend
- failures by reason
- success rate by method
- attempts and failures by day

### 4. Segments

Fields:

- `country`
- `state`
- `city`
- `device_type`
- `os`
- `customer_segment`
- `active_users`
- `conversion_rate_pct`
- `payment_success_rate_pct`

Visuals:

- active users by city
- conversion by device type
- payment success by OS
- weakest segments table

## Filters

Global filters:

- date range
- city
- device type
- OS
- customer segment

## Refresh Strategy

For demo simplicity:

- use direct query when connected to RDS MySQL
- use SPICE only when you need faster dashboard interaction

If using SPICE, configure a refresh interval that matches the demo story and call out that freshness depends on the dataset refresh schedule.

## Success Criteria

The dashboard is portfolio-ready when it can show:

- a live event generator running
- DMS task running
- dashboard freshness or recent replicated rows
- at least three KPI visuals
- one useful filter interaction
- one question-answering demo or screenshot
