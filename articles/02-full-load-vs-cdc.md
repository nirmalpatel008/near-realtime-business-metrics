# Full Load vs CDC: The Core Idea Behind Near Real-Time DMS Pipelines

AWS DMS demos often use the phrase **full load plus CDC**.

That phrase is doing a lot of work.

It describes how DMS can copy the existing state of a database and keep up with ongoing changes without asking the source application to stop writing.

## Full Load

Full load is the initial copy.

For each selected table, DMS reads the current rows from the source and writes them to the target.

Conceptually:

```text
SELECT * FROM customers;
SELECT * FROM accounts;
SELECT * FROM transactions;
```

Then DMS creates or loads the corresponding target tables.

Full load answers:

```text
What data already exists?
```

## CDC

CDC stands for change data capture.

For MySQL sources, DMS reads row-level changes from the binlog. That requires source settings such as:

- `binlog_format=ROW`
- `binlog_row_image=FULL`
- binlog retention
- backups enabled on RDS

CDC answers:

```text
What changed after the initial copy started?
```

## Why You Need Both

If you only do full load, the target becomes stale as soon as the source receives new writes.

If you only do CDC, you need a starting point and a consistent baseline.

Together, they create a practical migration and analytics pattern:

```text
copy existing rows
capture ongoing changes
apply both to the target
continue streaming changes
```

## The Demo Pattern

The demo proves this by doing three things at once:

1. Seed the source database with historical rows.
2. Start a DMS `full-load-and-cdc` task.
3. Generate new writes while the full load is still running.

When the full load completes, DMS applies the buffered changes and continues streaming new ones.

## Measuring Lag

The most understandable lag metric for demos is:

```text
target query time - source event timestamp
```

That tells you how long it took for a source event to become visible to a dashboard or downstream query.

CloudWatch DMS metrics such as `CDCLatencyTarget` are also useful for production monitoring.

## Common Gotchas

Primary keys matter.

Without a primary key, DMS may need slower row matching behavior for updates and deletes.

Binlog retention matters.

If DMS falls behind and the source binlog expires, you may need to resync.

DDL replication has limits.

Do not assume every schema change will replicate cleanly without testing.

## Why This Matters Beyond Migration

Full load plus CDC is not only a migration pattern.

It can also feed:

- reporting replicas
- analytics stores
- S3 raw layers
- data warehouses
- near real-time dashboards

That is the bridge from a database migration demo to a business metrics platform.
