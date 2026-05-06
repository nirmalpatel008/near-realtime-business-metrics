#!/usr/bin/env bash
# Portfolio demo: run KPI queries against the analytics target.
#
# Usage:
#   TGT_HOST=<target-endpoint> DB_PASSWORD='...' ./scripts/12-run-kpis.sh
set -euo pipefail

export AWS_PAGER=""
AWS_PROFILE=${AWS_PROFILE:-summit-demo}
AWS_REGION=${AWS_REGION:-us-east-1}
DB_USER=${DB_USER:-admin}
: "${DB_PASSWORD:?ERROR: Set DB_PASSWORD before running this script}"
STACK=${STACK:-dms-demo}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -z "${TGT_HOST:-}" ]]; then
  TGT_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
    --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='TargetEndpointAddress'].OutputValue" --output text)
fi

QUERIES=(
  "freshness.sql"
  "dau.sql"
  "conversion_rate.sql"
  "payment_success_rate.sql"
  "failed_payments_by_reason.sql"
  "funnel_daily.sql"
  "geo_segmentation.sql"
  "device_segmentation.sql"
  "reconciliation_daily.sql"
)

echo "Running portfolio KPI queries on target: $TGT_HOST"
echo

for query in "${QUERIES[@]}"; do
  query_path="$REPO_DIR/analytics/queries/$query"
  echo "================================================================"
  echo "$query"
  echo "================================================================"
  mysql -h "$TGT_HOST" -u "$DB_USER" -p"$DB_PASSWORD" demo -t < "$query_path"
  echo
done
