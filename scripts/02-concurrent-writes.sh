#!/usr/bin/env bash
# ACT 2: prove Full Load + CDC coexist.
# Starts a continuous write loop on SOURCE. Launch RIGHT AFTER start-task.sh.
# While DMS does Full Load of the 5k seeded orders, this loop keeps writing.
# DMS captures them from the binlog and applies after Full Load -> nothing lost.
#
# Usage:
#   SRC_HOST=<source-endpoint> DB_PASSWORD='...' ./02-concurrent-writes.sh
# Stop with Ctrl-C.
set -euo pipefail

export AWS_PAGER=""
AWS_PROFILE=${AWS_PROFILE:-summit-demo}
AWS_REGION=${AWS_REGION:-us-east-1}
DB_USER=${DB_USER:-admin}
: "${DB_PASSWORD:?ERROR: Set DB_PASSWORD before running this script}"
RATE_PER_SEC=${RATE_PER_SEC:-2}

if [[ -z "${SRC_HOST:-}" ]]; then
  SRC_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
    --stack-name dms-demo \
    --query "Stacks[0].Outputs[?OutputKey=='SourceEndpointAddress'].OutputValue" --output text)
fi

SLEEP=$(awk -v r="$RATE_PER_SEC" 'BEGIN{printf "%.3f", 1/r}')
echo "Writing $RATE_PER_SEC order(s)/sec to $SRC_HOST. Ctrl-C to stop."

i=0
while true; do
  i=$((i+1))
  mysql -h "$SRC_HOST" -u "$DB_USER" -p"$DB_PASSWORD" demo -N -e "
    INSERT INTO orders (customer_id, amount, status, event_ts)
    VALUES (1 + FLOOR(RAND()*1000), ROUND(100+RAND()*9900,2), 'LIVE', NOW(6));
  " >/dev/null 2>&1 && printf '.' || printf 'X'
  if (( i % 50 == 0 )); then echo " $i"; fi
  sleep "$SLEEP"
done
