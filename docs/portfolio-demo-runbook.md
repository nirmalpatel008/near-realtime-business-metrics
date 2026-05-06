# Portfolio Demo Runbook

This runbook uses the existing DMS stack, but swaps the simple Summit demo schema for the richer finance/product analytics schema.

## Goal

Show a near real-time business metrics pipeline:

```text
RDS MySQL source
  -> AWS DMS full load + CDC
  -> RDS MySQL analytics target
  -> KPI SQL queries
```

## Preflight

Set defaults:

```bash
export AWS_PROFILE=summit-demo
export AWS_REGION=us-east-1
export DB_PASSWORD='<set-a-strong-demo-password>'
```

Deploy the stack if it does not already exist:

```bash
./scripts/deploy.sh
```

Resolve source and target endpoints:

```bash
export SRC_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --stack-name dms-demo \
  --query "Stacks[0].Outputs[?OutputKey=='SourceEndpointAddress'].OutputValue" --output text)

export TGT_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --stack-name dms-demo \
  --query "Stacks[0].Outputs[?OutputKey=='TargetEndpointAddress'].OutputValue" --output text)
```

## Act 1: Seed Finance Data

Run on source:

```bash
mysql -h "$SRC_HOST" -u admin -p"$DB_PASSWORD" demo < scripts/10-seed-finance-source.sql
```

Expected tables:

- `regions`
- `customers`
- `accounts`
- `merchants`
- `devices`
- `transactions`
- `payments`
- `user_events`

## Act 2: Start DMS Full Load + CDC

```bash
./scripts/start-task.sh
```

Watch progress in another terminal:

```bash
watch -n2 ./scripts/status.sh
```

## Act 3: Generate Live Business Events

In another terminal:

```bash
./scripts/11-generate-live-finance-events.sh
```

This continuously writes:

- one transaction
- one payment
- five user events representing a mini funnel

The writes are wrapped in a transaction so DMS has a realistic CDC stream.

## Act 4: Run KPI Queries on Target

After DMS full load reaches 100%, run:

```bash
./scripts/13-measure-finance-lag.sh
```

This shows source event timestamp, target query timestamp, and lag in seconds for recent finance transactions.

In another terminal, run:

```bash
./scripts/12-run-kpis.sh
```

This shows:

- freshness
- DAU
- conversion rate
- payment success rate
- funnel counts
- geography segmentation
- device segmentation
- daily reconciliation metrics

## Act 5: Explain the Portfolio Story

Say:

> The original Summit demo proves full load plus CDC. This version uses that same foundation for a metrics workflow: synthetic product events, finance transactions, KPI queries, dashboards, and a catalog-backed question runner.

## Optional Act 6: QuickSight and Questions

Use this when you have built the optional QuickSight dashboard.

Open the dashboard described in:

```text
docs/quicksight-dashboard-guide.md
quicksight/dashboard-spec.md
```

Show:

- Executive Overview
- Funnel Analysis
- Payments Reliability
- Segments

Then ask a question using Amazon Q in QuickSight:

```text
Which city had the lowest payment success rate this week?
```

Other demo questions are listed in:

```text
quicksight/sample-questions.md
```

If QuickSight is not enabled, use the local query catalog runner:

```bash
python ai/ask_dashboard.py "How fresh is the dashboard?" --dry-run
python ai/ask_dashboard.py "Which city had the lowest payment success rate?"
```

## Cleanup

Stop the live generator with Ctrl-C.

Delete AWS resources:

```bash
./scripts/teardown.sh
```
