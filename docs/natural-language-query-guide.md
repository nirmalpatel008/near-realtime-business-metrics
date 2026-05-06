# Natural Language Query Guide

This guide covers the optional question-answering layer for the metrics project.

There are two paths:

1. **Amazon Q in QuickSight** for the AWS-native BI demo.
2. **Local query catalog runner** using `ai/query_catalog.yaml` for a lightweight, low-cost demo.

Use both in the portfolio story:

```text
Production-style BI path: QuickSight + Amazon Q
Developer-friendly fallback: query catalog + approved SQL files
```

## Why This Matters

Question answering turns the pipeline demo into something a product or finance stakeholder can use:

- product managers can ask KPI questions
- finance users can inspect payment reliability
- engineers can point every answer back to a metric definition
- learners can see why semantic modeling matters

## QuickSight / Amazon Q Approach

In QuickSight, create a topic for the dashboard dataset. The topic should expose friendly business terms rather than raw table names.

Recommended topic name:

```text
Business Metrics Pipeline
```

Recommended topic description:

```text
Near real-time product, payment, geography, and device metrics generated from synthetic finance-domain events replicated with AWS DMS.
```

## Field Naming

Use human-readable names:

| Raw field | Friendly name |
|---|---|
| `daily_active_users` | Daily active users |
| `conversion_rate_pct` | Conversion rate |
| `success_rate_pct` | Payment success rate |
| `payment_attempts` | Payment attempts |
| `successful_payments` | Successful payments |
| `failure_reason` | Payment failure reason |
| `device_type` | Device type |
| `os` | Operating system |
| `city` | City |
| `customer_segment` | Customer segment |
| `freshness_sec` | Dashboard freshness |

## Synonyms

Add synonyms so natural questions work better.

| Business term | Synonyms |
|---|---|
| Daily active users | DAU, active users, users active |
| Conversion rate | purchase conversion, checkout conversion, completed purchase rate |
| Payment success rate | success rate, payment reliability, successful payments |
| Failed payments | payment failures, failed attempts, unsuccessful payments |
| Gross transaction value | GTV, transaction volume, payment volume |
| Dashboard freshness | data freshness, data delay, pipeline delay, lag |
| City | geography, market, location |
| Device type | platform, channel, client device |

## Calculated Concepts

Define these in QuickSight where possible:

```text
Conversion rate = converted users / login users
Payment success rate = successful payments / payment attempts
Failed payment rate = failed payments / payment attempts
Freshness minutes = dashboard freshness seconds / 60
```

## Good Demo Questions

Use questions that map clearly to the dataset:

```text
What was DAU yesterday?
Show conversion rate by device type for the last 7 days.
Which city had the lowest payment success rate this week?
Show failed payments by reason.
Which operating system has the weakest conversion rate?
How fresh is the dashboard?
Show payment success rate by payment method.
Which region had the most active users?
```

## Questions to Avoid

Avoid questions that imply unavailable causal analysis:

```text
Why did users churn?
Which exact customer should receive a promotion?
Predict next month's revenue.
Which real bank caused the failures?
```

Instead, phrase them as exploratory questions:

```text
Which segment had lower conversion?
Which failure reason increased this week?
Which city should we investigate?
```

## Local Query Catalog Approach

The local runner uses:

```text
ai/query_catalog.yaml
analytics/queries/*.sql
ai/ask_dashboard.py
```

Flow:

```text
user question -> match approved query -> run SQL -> summarize results
```

This avoids open-ended SQL generation and works well in workshops.

Runnable guide:

```text
docs/ask-dashboard-guide.md
```

## Demo Script

1. Show the QuickSight dashboard.
2. Ask: "Which city had the lowest payment success rate this week?"
3. Show the answer and point to the same metric in the dashboard.
4. Ask: "How fresh is the dashboard?"
5. Explain that freshness comes from the CDC pipeline, not just the BI tool.

Closing line:

```text
The question layer only works because the data model and KPI definitions are clear.
```
