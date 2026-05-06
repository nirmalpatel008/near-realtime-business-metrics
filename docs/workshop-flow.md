# Workshop Flow

This project can support a 60-90 minute hands-on workshop.

## Module 1: CDC Concepts

Duration: 10 minutes

Teach:

- full load versus CDC
- MySQL binlog requirements
- why primary keys matter
- why replication lag is an operational metric

Activity:

- inspect `cloudformation/dms-demo.yaml`
- run `scripts/00-rds-context.sql`

## Module 2: Deploy the Foundation

Duration: 15 minutes

Teach:

- CloudFormation stack shape
- RDS source and target
- DMS endpoint and replication task
- cost and teardown expectations

Activity:

```bash
./scripts/deploy.sh
```

## Module 3: Seed and Replicate

Duration: 15 minutes

Teach:

- initial load
- ongoing writes during full load
- DMS task status

Activity:

```bash
mysql -h "$SRC_HOST" -u admin -p"$DB_PASSWORD" demo < scripts/01-seed-source.sql
./scripts/start-task.sh
./scripts/02-concurrent-writes.sh
watch -n2 ./scripts/status.sh
```

## Module 4: Measure Freshness

Duration: 10 minutes

Teach:

- source commit timestamp
- target visible timestamp
- CloudWatch DMS latency metrics

Activity:

```bash
./scripts/03-measure-lag.sh
./scripts/06-cdc-latency-metric.sh
```

## Module 5: Model Business Metrics

Duration: 20 minutes

Teach:

- event grain
- fact and dimension tables
- metric definitions
- segmentation by geography and device

Activity:

- read `docs/data-model.md`
- run queries from `analytics/queries`
- discuss dashboard layout

## Module 6: Reliability Checks

Duration: 10 minutes

Teach:

- reconciliation
- failed records
- schema drift
- freshness checks

Activity:

- review `docs/observability.md`
- design one alert and one reconciliation query

## Optional Module 7: Ask Your Dashboard

Duration: 10 minutes

Teach:

- constrained question answering
- query catalogs
- result summaries
- metric guardrails

Activity:

- review `ai/query_catalog.yaml`
- map sample user questions to approved KPI queries
