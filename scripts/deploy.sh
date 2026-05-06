#!/usr/bin/env bash
# Deploy the DMS demo stack.
# Usage: AWS_PROFILE=<profile> AWS_REGION=<region> DB_PASSWORD='<strong-password>' ./deploy.sh
set -euo pipefail

STACK=${STACK:-dms-demo}
REGION=${AWS_REGION:-us-east-1}
PROFILE=${AWS_PROFILE:-summit-demo}
: "${DB_PASSWORD:?ERROR: Set DB_PASSWORD to a strong demo database password before running deploy.sh}"
PASSWORD=$DB_PASSWORD
export AWS_PAGER=""

if [[ -n "${MY_IP_CIDR:-}" ]]; then
  MY_IP="$MY_IP_CIDR"
elif command -v curl >/dev/null; then
  MY_IP=$(curl -s https://checkip.amazonaws.com)/32
elif command -v wget >/dev/null; then
  MY_IP=$(wget -qO- https://checkip.amazonaws.com)/32
elif command -v python3 >/dev/null; then
  MY_IP=$(python3 -c "import urllib.request;print(urllib.request.urlopen('https://checkip.amazonaws.com').read().decode().strip())")/32
else
  echo "ERROR: install curl/wget OR export MY_IP_CIDR=x.x.x.x/32" >&2
  exit 1
fi
echo "Detected public IP: $MY_IP"

TEMPLATE="$(dirname "$0")/../cloudformation/dms-demo.yaml"

aws cloudformation deploy \
  --profile "$PROFILE" --region "$REGION" \
  --stack-name "$STACK" \
  --template-file "$TEMPLATE" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      MyIpCidr="$MY_IP" \
      DBMasterPassword="$PASSWORD"

echo
echo "=== Outputs ==="
aws cloudformation describe-stacks \
  --profile "$PROFILE" --region "$REGION" \
  --stack-name "$STACK" \
  --query 'Stacks[0].Outputs' --output table
