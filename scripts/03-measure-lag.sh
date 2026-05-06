#!/usr/bin/env bash
# ACT 3: prove "Near Real-Time" by measuring end-to-end lag live.
# Queries TARGET for the most recent LIVE orders and computes:
#   lag_sec = NOW() on target - event_ts stamped at source commit.
# Refreshes every second. Point the audience at the `lag_sec` column.
set -euo pipefail

export AWS_PAGER=""
AWS_PROFILE=${AWS_PROFILE:-summit-demo}
AWS_REGION=${AWS_REGION:-us-east-1}
DB_USER=${DB_USER:-admin}
: "${DB_PASSWORD:?ERROR: Set DB_PASSWORD before running this script}"

if [[ -z "${TGT_HOST:-}" ]]; then
  TGT_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
    --stack-name dms-demo \
    --query "Stacks[0].Outputs[?OutputKey=='TargetEndpointAddress'].OutputValue" --output text)
fi

echo "Polling $TGT_HOST for CDC lag. Ctrl-C to stop."

while true; do
  clear
  echo "=== Near Real-Time Replication Lag (source commit -> target visible) ==="
  date
  mysql -h "$TGT_HOST" -u "$DB_USER" -p"$DB_PASSWORD" demo -t -e "
    SELECT
      id, status,
      event_ts                                                  AS source_commit_ts,
      NOW(6)                                                    AS target_seen_ts,
      ROUND(TIMESTAMPDIFF(MICROSECOND, event_ts, NOW(6))/1e6,3) AS lag_sec
    FROM orders WHERE status='LIVE'
    ORDER BY id DESC LIMIT 10;

    SELECT
      COUNT(*)                                                                 AS live_rows,
      ROUND(AVG(TIMESTAMPDIFF(MICROSECOND, event_ts, NOW(6)))/1e6, 3)           AS avg_lag_sec,
      ROUND(MAX(TIMESTAMPDIFF(MICROSECOND, event_ts, NOW(6)))/1e6, 3)           AS max_lag_sec
    FROM orders WHERE status='LIVE' AND event_ts > NOW() - INTERVAL 60 SECOND;
  " 2>/dev/null
  sleep 1
done
