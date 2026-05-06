#!/usr/bin/env bash
# Delete the stack. Stops task first so CFN can clean up.
set -euo pipefail
STACK=${STACK:-dms-demo}
REGION=${AWS_REGION:-us-east-1}
PROFILE=${AWS_PROFILE:-summit-demo}
export AWS_PAGER=""

TASK_ARN=$(aws cloudformation describe-stacks \
  --profile "$PROFILE" --region "$REGION" \
  --stack-name "$STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='ReplicationTaskArn'].OutputValue" --output text 2>/dev/null || true)

if [[ -n "${TASK_ARN:-}" && "$TASK_ARN" != "None" ]]; then
  echo "Stopping DMS task..."
  aws dms stop-replication-task --profile "$PROFILE" --region "$REGION" \
    --replication-task-arn "$TASK_ARN" || true
  echo "Waiting ~30s for task to stop..."
  sleep 30
fi

echo "Deleting stack $STACK ..."
aws cloudformation delete-stack --profile "$PROFILE" --region "$REGION" --stack-name "$STACK"
aws cloudformation wait stack-delete-complete --profile "$PROFILE" --region "$REGION" --stack-name "$STACK"
echo "Done."
