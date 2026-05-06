#!/usr/bin/env bash
# Show DMS task status + stats (use during the demo).
set -euo pipefail
STACK=${STACK:-dms-demo}
REGION=${AWS_REGION:-us-east-1}
PROFILE=${AWS_PROFILE:-summit-demo}

TASK_ARN=$(aws cloudformation describe-stacks \
  --profile "$PROFILE" --region "$REGION" \
  --stack-name "$STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='ReplicationTaskArn'].OutputValue" --output text)

aws dms describe-replication-tasks \
  --profile "$PROFILE" --region "$REGION" \
  --filters Name=replication-task-arn,Values="$TASK_ARN" \
  --query 'ReplicationTasks[0].{Status:Status,Stats:ReplicationTaskStats}' \
  --output json
