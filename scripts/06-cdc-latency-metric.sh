#!/usr/bin/env bash
# ACT 5: DMS's own view of latency. Pulls CDCLatencyTarget from CloudWatch for
# the last 5 minutes. Shows seconds of lag between DMS applying to target and
# the source commit. This is the metric you'd alarm on in production.
set -euo pipefail

STACK=${STACK:-dms-demo}
REGION=${AWS_REGION:-us-east-1}
PROFILE=${AWS_PROFILE:-summit-demo}
export AWS_PAGER=""

TASK_ARN=$(aws cloudformation describe-stacks \
  --profile "$PROFILE" --region "$REGION" \
  --stack-name "$STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='ReplicationTaskArn'].OutputValue" --output text)

# CW dimension uses the task's external resource id (last segment of ARN)
TASK_ID=${TASK_ARN##*:}

RI_ID=$(aws dms describe-replication-instances \
  --profile "$PROFILE" --region "$REGION" \
  --query "ReplicationInstances[?ReplicationInstanceIdentifier=='${STACK}-ri'].ReplicationInstanceIdentifier" \
  --output text)

echo "Task: $TASK_ID   RI: $RI_ID"
echo "CDCLatencyTarget (seconds), last 5 minutes, 10s resolution:"

aws cloudwatch get-metric-statistics \
  --profile "$PROFILE" --region "$REGION" \
  --namespace AWS/DMS \
  --metric-name CDCLatencyTarget \
  --dimensions Name=ReplicationInstanceIdentifier,Value="$RI_ID" Name=ReplicationTaskIdentifier,Value="$TASK_ID" \
  --start-time "$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time   "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --period 10 \
  --statistics Average Maximum \
  --query 'Datapoints[*].[Timestamp,Average,Maximum]' \
  --output table
