# Architecture

## Current Demo Stack

The runnable part of the repo is still the DMS demo. It keeps the moving pieces small:

```text
RDS MySQL source
  -> AWS DMS replication instance
  -> RDS MySQL target
```

GitHub-rendered diagrams are available in [diagrams.md](diagrams.md).

The source database has the MySQL binlog settings required for CDC:

- `binlog_format=ROW`
- `binlog_row_image=Full`
- `binlog_checksum=NONE`
- `BackupRetentionPeriod >= 1`
- binlog retention set with `mysql.rds_set_configuration`

DMS runs one `full-load-and-cdc` replication task. The full load copies the existing tables. CDC captures ongoing `INSERT`, `UPDATE`, and `DELETE` changes from the binlog while the full load is still running.

## Extended Analytics Architecture

```text
Operational source: RDS MySQL
  -> CDC engine: AWS DMS
  -> Raw layer: Amazon S3
  -> Transform layer: Python or AWS Glue
  -> Analytics layer: RDS MySQL, Athena, or Redshift
  -> Dashboard: Streamlit or Amazon QuickSight
  -> Query layer: Amazon Q in QuickSight or local query catalog
```

## Build Order

### Step 1: Keep the DMS demo stable

The existing demo already proves the part that is hardest to explain on slides:

- infrastructure as code
- source database setup
- DMS replication task
- full load plus CDC
- replication lag measurement
- transaction consistency

### Step 2: Improve the source domain

Replace the simple `customers`, `accounts`, and `orders` demo schema with a richer synthetic finance/product schema:

- customers
- accounts
- merchants
- transactions
- payments
- user activity events
- devices
- regions

### Step 3: Add analytics marts

Create curated tables or views:

- `dim_customer`
- `dim_device`
- `dim_region`
- `dim_merchant`
- `fact_transactions`
- `fact_payments`
- `fact_user_events`
- `kpi_daily_metrics`

### Step 4: Add dashboarding

Use the lowest-friction option first:

1. SQL queries against the DMS target.
2. Streamlit dashboard against RDS MySQL or local exported CSV files.
3. Optional QuickSight dashboard for the AWS-native path.

### Step 5: Add S3 and transformations

Once the CDC demo and KPI queries are clear, add an S3 raw target path:

```text
s3://near-realtime-business-metrics/raw/customers/
s3://near-realtime-business-metrics/raw/transactions/
s3://near-realtime-business-metrics/raw/payments/
s3://near-realtime-business-metrics/raw/user_events/
```

Then transform raw data into curated tables using Python first, with AWS Glue as an optional cloud implementation.

### Step 6: Add the query layer last

The local query runner should answer business questions from approved KPI SQL. It should not generate arbitrary SQL:

```text
user question -> query catalog match -> approved SQL -> result summary
```

## MVP Scope

The first complete version should include:

- current CloudFormation DMS stack
- richer synthetic source schema
- live event generation
- KPI SQL queries
- lag and reconciliation checks
- one dashboard path
- docs that let someone else run the demo

## Optional Cloud Extensions

- S3 raw layer
- Glue transformations
- Athena or Redshift analytics layer
- QuickSight dashboard
- Amazon Q in QuickSight questions
- CloudWatch alarms
- Step Functions orchestration

These are valuable, but they should not block the MVP.

## BI and Question-Answering Path

The AWS-native BI path is:

```text
analytics tables or views
  -> QuickSight datasets
  -> QuickSight dashboard
  -> Amazon Q in QuickSight topic
  -> business questions
```

Use curated KPI datasets instead of raw event tables for questions. The terms are clearer, and the answers line up with the dashboard.
