#!/usr/bin/env bash
# Portfolio demo: measure end-to-end lag for live finance transactions.
# Queries TARGET for recent transactions and computes:
#   lag_sec = NOW() on target - event_ts stamped at source.
# Refreshes every second.
set -euo pipefail

export AWS_PAGER=""
AWS_PROFILE=${AWS_PROFILE:-summit-demo}
AWS_REGION=${AWS_REGION:-us-east-1}
DB_USER=${DB_USER:-admin}
: "${DB_PASSWORD:?ERROR: Set DB_PASSWORD before running this script}"
STACK=${STACK:-dms-demo}

if [[ -z "${TGT_HOST:-}" ]]; then
  TGT_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
    --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='TargetEndpointAddress'].OutputValue" --output text)
fi

echo "Polling $TGT_HOST for finance CDC lag. Ctrl-C to stop."

while true; do
  clear
  echo "=== Finance CDC Lag (source event -> target visible) ==="
  date
  mysql -h "$TGT_HOST" -u "$DB_USER" -p"$DB_PASSWORD" demo -t -e "
    SELECT
      transaction_id,
      transaction_status,
      channel,
      amount,
      event_ts AS source_event_ts,
      NOW(6) AS target_seen_ts,
      ROUND(TIMESTAMPDIFF(MICROSECOND, event_ts, NOW(6))/1e6, 3) AS lag_sec
    FROM transactions
    WHERE event_ts > NOW(6) - INTERVAL 2 MINUTE
    ORDER BY transaction_id DESC
    LIMIT 10;

    SELECT
      COUNT(*) AS recent_transactions,
      ROUND(AVG(TIMESTAMPDIFF(MICROSECOND, event_ts, NOW(6)))/1e6, 3) AS avg_lag_sec,
      ROUND(MAX(TIMESTAMPDIFF(MICROSECOND, event_ts, NOW(6)))/1e6, 3) AS max_lag_sec
    FROM transactions
    WHERE event_ts > NOW(6) - INTERVAL 2 MINUTE;
  " 2>/dev/null
  sleep 1
done
