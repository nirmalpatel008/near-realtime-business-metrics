#!/usr/bin/env bash
# Portfolio demo: generate live finance/product events on SOURCE.
# Run right after scripts/start-task.sh while DMS is doing full load + CDC.
#
# Usage:
#   SRC_HOST=<source-endpoint> DB_PASSWORD='...' ./scripts/11-generate-live-finance-events.sh
# Stop with Ctrl-C.
set -euo pipefail

export AWS_PAGER=""
AWS_PROFILE=${AWS_PROFILE:-summit-demo}
AWS_REGION=${AWS_REGION:-us-east-1}
DB_USER=${DB_USER:-admin}
: "${DB_PASSWORD:?ERROR: Set DB_PASSWORD before running this script}"
RATE_PER_SEC=${RATE_PER_SEC:-2}
STACK=${STACK:-dms-demo}

if [[ -z "${SRC_HOST:-}" ]]; then
  SRC_HOST=$(aws cloudformation describe-stacks --profile "$AWS_PROFILE" --region "$AWS_REGION" \
    --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='SourceEndpointAddress'].OutputValue" --output text)
fi

SLEEP=$(awk -v r="$RATE_PER_SEC" 'BEGIN{printf "%.3f", 1/r}')
echo "Writing $RATE_PER_SEC synthetic finance event set(s)/sec to $SRC_HOST. Ctrl-C to stop."

i=0
while true; do
  i=$((i+1))
  mysql -h "$SRC_HOST" -u "$DB_USER" -p"$DB_PASSWORD" demo -N -e "
    START TRANSACTION;

    SET @customer_id := 1 + FLOOR(RAND() * 1000);
    SET @merchant_id := 1 + FLOOR(RAND() * 200);
    SET @device_id := (
      SELECT device_id
      FROM devices
      WHERE customer_id = @customer_id
      ORDER BY RAND()
      LIMIT 1
    );
    SET @device_id := COALESCE(@device_id, 1 + FLOOR(RAND() * 1200));
    SET @amount := ROUND(50 + RAND() * 25000, 2);
    SET @channel := ELT(1 + FLOOR(RAND() * 3), 'mobile_app', 'web', 'partner_api');
    SET @payment_method := ELT(1 + FLOOR(RAND() * 5), 'upi', 'card', 'netbanking', 'wallet', 'bnpl');
    SET @is_success := RAND() >= 0.12;
    SET @event_ts := NOW(6);
    SET @session_id := CONCAT('live_', @customer_id, '_', UNIX_TIMESTAMP(@event_ts), '_', FLOOR(RAND() * 100000));

    INSERT INTO transactions (customer_id, merchant_id, amount, currency, transaction_status, channel, event_ts, created_ts)
    VALUES (
      @customer_id,
      @merchant_id,
      @amount,
      'INR',
      IF(@is_success, 'COMPLETED', 'FAILED'),
      @channel,
      @event_ts,
      @event_ts
    );

    SET @transaction_id := LAST_INSERT_ID();

    INSERT INTO payments (transaction_id, customer_id, payment_method, payment_status, failure_reason, processor_latency_ms, event_ts)
    VALUES (
      @transaction_id,
      @customer_id,
      @payment_method,
      IF(@is_success, 'SUCCESS', 'FAILED'),
      IF(@is_success, NULL, ELT(1 + FLOOR(RAND() * 5), 'INSUFFICIENT_FUNDS', 'BANK_TIMEOUT', 'RISK_DECLINED', 'INVALID_METHOD', 'NETWORK_ERROR')),
      80 + FLOOR(RAND() * 900),
      @event_ts + INTERVAL 100000 MICROSECOND
    );

    INSERT INTO user_events (customer_id, session_id, device_id, event_type, merchant_id, transaction_id, event_ts, metadata_json)
    VALUES
      (@customer_id, @session_id, @device_id, 'login', @merchant_id, NULL, @event_ts - INTERVAL 4 SECOND, JSON_OBJECT('channel', @channel, 'live', true)),
      (@customer_id, @session_id, @device_id, 'view_merchant', @merchant_id, NULL, @event_ts - INTERVAL 3 SECOND, JSON_OBJECT('channel', @channel, 'live', true)),
      (@customer_id, @session_id, @device_id, 'payment_initiated', @merchant_id, @transaction_id, @event_ts - INTERVAL 2 SECOND, JSON_OBJECT('channel', @channel, 'live', true)),
      (@customer_id, @session_id, @device_id, IF(@is_success, 'payment_success', 'payment_failed'), @merchant_id, @transaction_id, @event_ts - INTERVAL 1 SECOND, JSON_OBJECT('channel', @channel, 'live', true)),
      (@customer_id, @session_id, @device_id, IF(@is_success, 'purchase_completed', 'purchase_abandoned'), @merchant_id, @transaction_id, @event_ts, JSON_OBJECT('channel', @channel, 'live', true));

    COMMIT;
  " >/dev/null 2>&1 && printf '.' || printf 'X'

  if (( i % 25 == 0 )); then echo " $i"; fi
  sleep "$SLEEP"
done
