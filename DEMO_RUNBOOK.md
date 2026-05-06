# Demo Runbook

**Session:** Near Real-Time Data Pipelines with AWS DMS  
**Total live-demo time:** about 7 minutes

This is the original Summit demo flow. It is intentionally GitHub-safe: no live database passwords, no hardcoded RDS endpoints, and no AWS access keys.

## Preflight

Set these values in each terminal:

```bash
export AWS_PROFILE=summit-demo
export AWS_REGION=us-east-1
export DB_PASSWORD='<set-a-strong-demo-password>'
```

Resolve current stack outputs:

```bash
export SRC_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --stack-name dms-demo \
  --query "Stacks[0].Outputs[?OutputKey=='SourceEndpointAddress'].OutputValue" --output text)

export TGT_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --stack-name dms-demo \
  --query "Stacks[0].Outputs[?OutputKey=='TargetEndpointAddress'].OutputValue" --output text)

export TASK_ARN=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --stack-name dms-demo \
  --query "Stacks[0].Outputs[?OutputKey=='ReplicationTaskArn'].OutputValue" --output text)
```

Open four terminal panes:

| Pane | Purpose |
|---|---|
| 1 | Main commands |
| 2 | Concurrent writes loop |
| 3 | DMS task status |
| 4 | Replication lag |

## Step 0: Deploy Infra

Only run this if the stack does not exist yet:

```bash
./scripts/deploy.sh
```

## Step 1: Fresh Reset

Stop the DMS task if it is running:

```bash
aws --no-cli-pager dms stop-replication-task --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --replication-task-arn "$TASK_ARN" 2>/dev/null || true
```

Wait until it is stopped:

```bash
while [[ $(aws --no-cli-pager dms describe-replication-tasks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --filters Name=replication-task-arn,Values="$TASK_ARN" \
  --query 'ReplicationTasks[0].Status' --output text) != "stopped" ]]; do
  echo "waiting for task to stop..."
  sleep 5
done
echo "task stopped"
```

## Step 2: Act 1 - Show Binlog Prereqs

```bash
mysql -h "$SRC_HOST" -u admin -p"$DB_PASSWORD" demo < scripts/00-rds-context.sql
```

Say:

> These are the CDC prereqs from the architecture slide: `log_bin=ON`, `binlog_format=ROW`, `binlog_row_image=FULL`, and binlog retention. Here they are live on the source.

## Step 3: Act 2 Prep - Seed Source

```bash
mysql -h "$SRC_HOST" -u admin -p"$DB_PASSWORD" demo < scripts/01-seed-source.sql
```

Expected output:

```text
customers=1000, accounts=1000, orders=5000
```

## Step 4: Act 2 - Start DMS Task and Concurrent Writes

Pane 1:

```bash
./scripts/start-task.sh
```

Pane 2:

```bash
./scripts/02-concurrent-writes.sh
```

Pane 3:

```bash
watch -n2 ./scripts/status.sh
```

Say:

> Full Load is copying the existing rows. These LIVE orders are being written during the load, captured from the binlog, buffered, and applied after Full Load catches up.

Wait until `FullLoadProgressPercent` reaches 100.

## Step 5: Act 3 - Show Near-Real-Time Lag

Pane 4:

```bash
./scripts/03-measure-lag.sh
```

Say:

> This `lag_sec` column is the end-to-end story: source commit to target visible.

## Step 6: Act 4 - Transaction Integrity

Stop pane 2 with Ctrl-C.

Run:

```bash
mysql -h "$SRC_HOST" -u admin -p"$DB_PASSWORD" demo < scripts/04-transaction-demo.sql
mysql -h "$TGT_HOST" -u admin -p"$DB_PASSWORD" demo < scripts/05-verify-target.sql
```

Say:

> Both sides of the transaction land together on the target. DMS is a pipeline, not a row shipper.

## Step 7: Act 5 - CloudWatch Latency Metric

```bash
./scripts/06-cdc-latency-metric.sh
```

Say:

> This is the metric you alarm on in production: `CDCLatencyTarget`.

## Teardown

```bash
./scripts/teardown.sh
```

## Quick Reference

| Thing | Value |
|---|---|
| Source DB | Resolve from CloudFormation output `SourceEndpointAddress` |
| Target DB | Resolve from CloudFormation output `TargetEndpointAddress` |
| DB user | `admin` |
| DB password | Set locally as `DB_PASSWORD`; do not commit it |
| DB name | `demo` |
| AWS profile | `summit-demo` |
| Region | `us-east-1` |
| Stack name | `dms-demo` |
| Task identifier | `dms-demo-task` |

Refresh outputs:

```bash
aws --no-cli-pager cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --stack-name dms-demo --query 'Stacks[0].Outputs' --output table
```
