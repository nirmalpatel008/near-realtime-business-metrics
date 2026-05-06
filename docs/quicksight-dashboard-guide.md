# QuickSight Dashboard Guide

This is the optional AWS-native dashboard path for the portfolio project.

The core demo remains:

```text
RDS MySQL source -> AWS DMS -> RDS MySQL target -> KPI SQL
```

QuickSight adds the dashboard layer:

```text
RDS MySQL target or analytics store -> QuickSight dataset -> dashboard -> Amazon Q questions
```

## When to Use This Path

Use QuickSight when you want to demonstrate:

- BI dashboard design
- AWS-native analytics delivery
- stakeholder-facing metrics
- business questions with Amazon Q in QuickSight

Keep it optional for workshops because QuickSight and Amazon Q require account setup and can add cost.

## Recommended Data Source

Start with the DMS target RDS MySQL database.

Later options:

- Athena over S3 curated data
- Redshift Serverless analytics marts
- SPICE import for faster demo dashboards

For the first version, connect QuickSight to the target database and build datasets from SQL views or custom SQL.

## Dataset Strategy

Create one dataset per dashboard theme:

- `kpi_daily_metrics`
- `funnel_daily`
- `payment_reliability`
- `geo_device_segments`
- `recent_transactions`
- `data_freshness`

You can implement these as QuickSight custom SQL queries using the files in `analytics/queries`, or later promote them into database views.

## Dashboard Sheets

### Sheet 1: Executive Overview

Purpose: one-screen business summary.

Visuals:

- KPI: Daily Active Users
- KPI: Conversion Rate
- KPI: Payment Success Rate
- KPI: Gross Transaction Value
- Line chart: DAU over time
- Line chart: conversion rate over time
- Line chart: payment success rate over time
- Table or KPI: dashboard freshness in seconds

Filters:

- date range
- region
- device type
- customer segment

### Sheet 2: Funnel Analysis

Purpose: show where users drop off.

Visuals:

- funnel visual: login -> view merchant -> payment initiated -> payment success -> purchase completed
- line chart: purchase sessions over time
- bar chart: drop-off by step
- table: daily funnel counts

Filters:

- date range
- device type
- OS
- region

### Sheet 3: Payments Reliability

Purpose: show operational reliability and payment failures.

Visuals:

- KPI: payment success rate
- bar chart: failed payments by failure reason
- bar chart: payment success by payment method
- heatmap or table: failure rate by city and method
- line chart: payment attempts and failures over time

Filters:

- date range
- payment method
- region
- merchant category

### Sheet 4: Segments

Purpose: let viewers compare behavior by geography and device.

Visuals:

- map or bar chart: active users by city
- bar chart: conversion rate by device type
- bar chart: payment success rate by OS
- table: top cities by gross transaction value
- table: weakest segments by payment success rate

Filters:

- date range
- city
- device type
- OS
- customer segment

## Calculated Fields

Recommended QuickSight calculated fields:

```text
conversion_rate = converted_users / login_users
payment_success_rate = successful_payments / payment_attempts
freshness_minutes = freshness_sec / 60
gross_transaction_value = sum(amount)
failed_payment_rate = failed_payments / payment_attempts
```

Use percentage formatting for conversion and success rates.

## Demo Script

1. Show source database receiving live events.
2. Show DMS task running.
3. Open QuickSight dashboard.
4. Point to freshness and say the dashboard is reading replicated operational changes.
5. Walk through DAU, conversion, and payment success.
6. Filter to one city or device type.
7. Ask a question using Amazon Q in QuickSight.

## Screenshot Plan

After the dashboard is built, add screenshots to:

```text
quicksight/screenshots/
assets/dashboard-screenshots/
```

Recommended screenshots:

- executive overview
- funnel analysis
- payments reliability
- segment filters
- question and answer

## Cost Guard

QuickSight and Amazon Q features may create charges. Keep this as an optional extension. For public workshops, use screenshots or a recorded demo unless every participant has a prepared AWS account and budget guardrails.
