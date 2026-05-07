#!/usr/bin/env bash
# Delete the stack. Stops task first so CFN can clean up.
set -euo pipefail
STACK=${STACK:-dms-demo}
QUICKSIGHT_STACK=${QUICKSIGHT_STACK:-${STACK}-quicksight}
REGION=${AWS_REGION:-us-east-1}
PROFILE=${AWS_PROFILE:-summit-demo}
export AWS_PAGER=""
ACCOUNT_ID=$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text 2>/dev/null || true)
TEMPLATE_BUCKET=${TEMPLATE_BUCKET:-${STACK}-quicksight-cfn-${ACCOUNT_ID}-${REGION}}

if aws cloudformation describe-stacks \
  --profile "$PROFILE" --region "$REGION" \
  --stack-name "$QUICKSIGHT_STACK" >/dev/null 2>&1; then
  echo "Deleting QuickSight stack $QUICKSIGHT_STACK ..."
  aws cloudformation delete-stack --profile "$PROFILE" --region "$REGION" --stack-name "$QUICKSIGHT_STACK"
  aws cloudformation wait stack-delete-complete --profile "$PROFILE" --region "$REGION" --stack-name "$QUICKSIGHT_STACK"
fi

if [[ -n "$ACCOUNT_ID" ]] && aws s3api head-bucket --profile "$PROFILE" --bucket "$TEMPLATE_BUCKET" >/dev/null 2>&1; then
  echo "Deleting QuickSight CloudFormation template bucket $TEMPLATE_BUCKET ..."
  aws s3 rm "s3://$TEMPLATE_BUCKET" --profile "$PROFILE" --recursive >/dev/null
  aws s3 rb "s3://$TEMPLATE_BUCKET" --profile "$PROFILE" >/dev/null
fi

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
