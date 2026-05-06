#!/usr/bin/env bash
# Start the DMS replication task (full-load-and-cdc).
set -euo pipefail

STACK=${STACK:-dms-demo}
REGION=${AWS_REGION:-us-east-1}
PROFILE=${AWS_PROFILE:-summit-demo}
export AWS_PAGER=""

TASK_ARN=$(aws cloudformation describe-stacks \
  --profile "$PROFILE" --region "$REGION" \
  --stack-name "$STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='ReplicationTaskArn'].OutputValue" \
  --output text)

echo "Starting task: $TASK_ARN"
aws dms start-replication-task \
  --profile "$PROFILE" --region "$REGION" \
  --replication-task-arn "$TASK_ARN" \
  --start-replication-task-type start-replication

echo "Follow progress:"
echo "  aws dms describe-replication-tasks --profile $PROFILE --region $REGION --query 'ReplicationTasks[?ReplicationTaskArn==\`$TASK_ARN\`].[Status,ReplicationTaskStats]'"
