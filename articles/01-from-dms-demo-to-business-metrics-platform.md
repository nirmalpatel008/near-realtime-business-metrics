# From AWS DMS Demo to Near Real-Time Business Metrics Platform

Most database migration demos stop once rows arrive on the target.

That is useful, but it leaves an important follow-up question: what else can we build once the target stays fresh?

This project started as an AWS Summit demo about AWS DMS full load plus CDC. The original goal was simple:

```text
RDS MySQL source -> AWS DMS -> RDS MySQL target
```

The evolved goal is broader:

```text
operational database changes
  -> CDC replication
  -> analytics modeling
  -> KPI queries
  -> dashboards
  -> business questions
```

## Why CDC Matters

Product and finance teams do not want to wait for a nightly batch job to answer basic questions:

- How many users are active today?
- Is conversion dropping?
- Are payment failures increasing?
- Which city or device type is underperforming?

Change data capture gives the pipeline a fresh stream of operational changes without rewriting the application.

## The Foundation

The base demo uses:

- RDS MySQL source
- AWS DMS replication instance
- RDS MySQL target
- MySQL binlog in ROW format
- one `full-load-and-cdc` DMS task

DMS first copies the existing tables, then continues applying new `INSERT`, `UPDATE`, and `DELETE` events from the binlog.

## The Business Scenario

The portfolio version uses synthetic finance/product data:

- customers
- accounts
- merchants
- transactions
- payments
- user activity events
- devices
- regions

The data is synthetic, but realistic enough for demos and workshops.

## The KPIs

The project defines starter SQL for:

- Daily Active Users
- conversion rate
- payment success rate
- failed payments by reason
- funnel counts
- geography segmentation
- device segmentation
- dashboard freshness

This is where a migration demo becomes a business metrics platform.

## The Question Layer

There are two question-answering paths:

1. Amazon Q in QuickSight for the AWS-native BI experience.
2. A local query catalog runner for a low-cost demo.

The local runner does not generate arbitrary SQL. It maps questions to approved queries:

```text
user question -> query catalog -> approved SQL -> result summary
```

That constraint is useful. It keeps the demo easy to explain and keeps every answer tied to a known metric.

## What This Shows in a Portfolio

This project demonstrates more than cloud service knowledge:

- reproducible infrastructure
- realistic synthetic data
- developer-friendly scripts
- clear runbooks
- metric definitions
- dashboard design
- query catalog guardrails
- cost and teardown awareness

That combination is what turns a demo into a developer experience project.

## Closing Thought

AWS DMS is often introduced as a migration tool. But once you understand full load plus CDC, it becomes a foundation for near real-time analytics.

The important shift is not technical. It is narrative:

```text
I moved rows
```

becomes:

```text
I built a platform that turns operational changes into business decisions
```
