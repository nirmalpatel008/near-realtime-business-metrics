# Observability and Data Quality

The goal is practical reliability, not heavyweight platform engineering.

## Pipeline Monitoring

Track the DMS task:

- task status
- full load progress percentage
- table-level row counts
- elapsed full load time
- CDC start time

Existing script:

```bash
./scripts/status.sh
```

## Replication Lag

Track lag in two ways.

### Application-visible lag

Measure:

```text
target query time - source event timestamp
```

Existing script:

```bash
./scripts/03-measure-lag.sh
```

This is the clearest metric for demos because it shows when a dashboard could read the event.

### DMS CloudWatch lag

Track:

- `CDCLatencySource`
- `CDCLatencyTarget`

Existing script:

```bash
./scripts/06-cdc-latency-metric.sh
```

## Reconciliation Checks

Start with simple checks:

- source row count versus target row count
- source transaction amount sum versus target transaction amount sum
- payment status counts by day
- max source `event_ts` versus max target `event_ts`

Example checks:

```sql
SELECT COUNT(*) FROM transactions;
SELECT DATE(event_ts), COUNT(*), SUM(amount)
FROM transactions
GROUP BY DATE(event_ts);
```

## Freshness Metrics

Dashboard freshness:

```sql
SELECT TIMESTAMPDIFF(SECOND, MAX(event_ts), NOW()) AS freshness_sec
FROM user_events;
```

Recommended SLA for demos:

```text
freshness_sec < 300
```

## Failed Records

For the current DMS-to-MySQL path, failed records usually surface through:

- DMS task logs
- target apply errors
- missing primary keys
- incompatible DDL
- data type mismatches

For a future S3 target, add:

- rejected records prefix
- error-count metric
- sample failed record capture
- retry notes

## Schema Drift

Detect drift by comparing expected columns with actual source columns.

Recommended lightweight check:

```sql
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'demo'
ORDER BY table_name, ordinal_position;
```

Document new columns before promoting them into dashboards.

## Practical Alerts

Add alerts only after the MVP:

- DMS task status is not `running`
- `CDCLatencyTarget` exceeds 60 seconds for 5 minutes
- dashboard freshness exceeds 5 minutes
- reconciliation count mismatch exceeds expected tolerance
- failed record count is greater than zero
