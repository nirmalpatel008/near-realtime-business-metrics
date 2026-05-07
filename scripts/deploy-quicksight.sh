#!/usr/bin/env bash
# Deploy optional QuickSight assets for the business metrics demo.
#
# Prereqs:
#   1. Deploy the base DMS stack first.
#   2. Enable QuickSight in the same AWS account and Region.
#   3. Export DB_PASSWORD or keep it in local .env.
#
# Optional:
#   QUICKSIGHT_PRINCIPAL_ARN=<user-or-group-arn> ./scripts/deploy-quicksight.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$REPO_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$REPO_DIR/.env"
  set +a
fi

STACK=${STACK:-dms-demo}
QUICKSIGHT_STACK=${QUICKSIGHT_STACK:-${STACK}-quicksight}
REGION=${AWS_REGION:-us-east-1}
PROFILE=${AWS_PROFILE:-summit-demo}
DB_USER=${DB_USER:-admin}
DB_NAME=${DB_NAME:-demo}
QUICKSIGHT_PRINCIPAL_ARN=${QUICKSIGHT_PRINCIPAL_ARN:-}
: "${DB_PASSWORD:?ERROR: Set DB_PASSWORD before running deploy-quicksight.sh}"
export AWS_PAGER=""

get_output() {
  local key=$1
  aws cloudformation describe-stacks \
    --profile "$PROFILE" --region "$REGION" \
    --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='${key}'].OutputValue" \
    --output text
}

ACCOUNT_ID=$(aws sts get-caller-identity \
  --profile "$PROFILE" \
  --query Account \
  --output text)
TEMPLATE_BUCKET=${TEMPLATE_BUCKET:-${STACK}-quicksight-cfn-${ACCOUNT_ID}-${REGION}}

echo "Checking QuickSight account settings..."
if ! aws quicksight describe-account-settings \
  --profile "$PROFILE" --region "$REGION" \
  --aws-account-id "$ACCOUNT_ID" >/dev/null 2>&1; then
  echo "ERROR: QuickSight is not enabled or not reachable for account $ACCOUNT_ID in $REGION." >&2
  echo "Enable QuickSight first, then rerun this script." >&2
  exit 1
fi

if [[ -z "$QUICKSIGHT_PRINCIPAL_ARN" ]]; then
  echo "WARNING: QUICKSIGHT_PRINCIPAL_ARN is not set."
  echo "The stack can create assets, but you may need to grant asset permissions in QuickSight."
  echo "Example user ARN: arn:aws:quicksight:${REGION}:${ACCOUNT_ID}:user/default/<username>"
fi

DB_SG_ID=$(get_output DbSecurityGroupId)
TARGET_ENDPOINT=$(get_output TargetEndpointAddress)

TEMPLATE="$REPO_DIR/cloudformation/quicksight-mysql.yaml"

if ! aws s3api head-bucket --profile "$PROFILE" --bucket "$TEMPLATE_BUCKET" >/dev/null 2>&1; then
  echo "Creating CloudFormation template bucket: $TEMPLATE_BUCKET"
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --profile "$PROFILE" --region "$REGION" --bucket "$TEMPLATE_BUCKET" >/dev/null
  else
    aws s3api create-bucket \
      --profile "$PROFILE" --region "$REGION" \
      --bucket "$TEMPLATE_BUCKET" \
      --create-bucket-configuration LocationConstraint="$REGION" >/dev/null
  fi
fi

echo "Deploying QuickSight stack: $QUICKSIGHT_STACK"
aws cloudformation deploy \
  --profile "$PROFILE" --region "$REGION" \
  --stack-name "$QUICKSIGHT_STACK" \
  --template-file "$TEMPLATE" \
  --s3-bucket "$TEMPLATE_BUCKET" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
      ProjectName="$STACK" \
      AwsAccountId="$ACCOUNT_ID" \
      QuickSightPrincipalArn="$QUICKSIGHT_PRINCIPAL_ARN" \
      DbSecurityGroupId="$DB_SG_ID" \
      TargetEndpointAddress="$TARGET_ENDPOINT" \
      DBName="$DB_NAME" \
      DBMasterUsername="$DB_USER" \
      DBMasterPassword="$DB_PASSWORD"

echo
echo "=== QuickSight Outputs ==="
aws cloudformation describe-stacks \
  --profile "$PROFILE" --region "$REGION" \
  --stack-name "$QUICKSIGHT_STACK" \
  --query 'Stacks[0].Outputs' --output table

if [[ -n "$QUICKSIGHT_PRINCIPAL_ARN" ]]; then
  TOPIC_PERMISSIONS_FILE=$(mktemp)
  cleanup_topic_permissions() {
    rm -f "$TOPIC_PERMISSIONS_FILE"
  }
  trap cleanup_topic_permissions EXIT

  cat > "$TOPIC_PERMISSIONS_FILE" <<EOF
[
  {
    "Principal": "$QUICKSIGHT_PRINCIPAL_ARN",
    "Actions": [
      "quicksight:DescribeTopic",
      "quicksight:DescribeTopicPermissions",
      "quicksight:UpdateTopic",
      "quicksight:DeleteTopic",
      "quicksight:UpdateTopicPermissions",
      "quicksight:ListTopicRefreshSchedules",
      "quicksight:DescribeTopicRefresh",
      "quicksight:CreateTopicRefreshSchedule",
      "quicksight:DeleteTopicRefreshSchedule",
      "quicksight:UpdateTopicRefreshSchedule",
      "quicksight:DescribeTopicRefreshSchedule"
    ]
  }
]
EOF

  TOPIC_PERMISSIONS_URI="file://$TOPIC_PERMISSIONS_FILE"
  if command -v cygpath >/dev/null 2>&1; then
    TOPIC_PERMISSIONS_URI="file://$(cygpath -w "$TOPIC_PERMISSIONS_FILE")"
  fi

  echo
  echo "Granting QuickSight topic permissions to $QUICKSIGHT_PRINCIPAL_ARN ..."
  aws quicksight update-topic-permissions \
    --profile "$PROFILE" --region "$REGION" \
    --aws-account-id "$ACCOUNT_ID" \
    --topic-id "${STACK}-business-metrics-topic" \
    --grant-permissions "$TOPIC_PERMISSIONS_URI" >/dev/null
fi
