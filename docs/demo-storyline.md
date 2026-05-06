# Demo Storyline

Use this as a 3-5 minute portfolio demo or video script.

## 0:00-0:45: Problem

Product and finance teams need fresh metrics: active users, payment success, conversion, drop-offs, and regional trends. Traditional nightly batch jobs make dashboards stale, and hand-built change capture is fragile.

**Line to say:**

> This project starts with a transactional database and turns changes into near real-time business metrics.

## 0:45-1:45: CDC Foundation

Show the source RDS MySQL database, binlog prerequisites, and the DMS replication task.

Run or show:

```bash
mysql -h "$SRC_HOST" -u admin -p"$DB_PASSWORD" demo < scripts/00-rds-context.sql
./scripts/start-task.sh
./scripts/status.sh
```

**Line to say:**

> DMS handles the initial full load and keeps reading new changes from the MySQL binlog.

## 1:45-2:45: Live Events

Start synthetic writes.

```bash
./scripts/02-concurrent-writes.sh
```

Show replication lag:

```bash
./scripts/03-measure-lag.sh
```

**Line to say:**

> The important number is source event time to target visible time. That is the freshness users actually feel in a dashboard.

## 2:45-3:45: Business KPIs

Show the KPI query files in `analytics/queries`.

Highlight:

- DAU
- conversion rate
- payment success
- funnel
- geo/device cuts

**Line to say:**

> Once CDC is reliable, the data engineering problem becomes shaping raw events into metrics that product and business teams understand.

## 3:45-4:30: Dashboard and Query Extension

Show the intended QuickSight dashboard layout or screenshots. Then show `quicksight/topic-design.md` and `ai/query_catalog.yaml`.

Ask:

> Which region had the weakest payment success rate yesterday?

**Line to say:**

> The question layer works because the KPI definitions are already curated. QuickSight uses a topic; the local runner maps questions to approved KPI queries.

## 4:30-5:00: Close

**Closing line:**

> This began as an AWS DMS migration demo, but the same foundation becomes a practical near real-time metrics platform.
