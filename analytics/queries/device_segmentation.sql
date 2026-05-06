-- Conversion and payment success by device type and OS.

WITH event_metrics AS (
  SELECT
    DATE(e.event_ts) AS metric_date,
    d.device_type,
    d.os,
    COUNT(DISTINCT CASE WHEN e.event_type = 'login' THEN e.customer_id END) AS login_users,
    COUNT(DISTINCT CASE WHEN e.event_type = 'purchase_completed' THEN e.customer_id END) AS converted_users
  FROM user_events e
  LEFT JOIN devices d ON d.device_id = e.device_id
  GROUP BY DATE(e.event_ts), d.device_type, d.os
),
payment_metrics AS (
  SELECT
    DATE(p.event_ts) AS metric_date,
    d.device_type,
    d.os,
    COUNT(*) AS payment_attempts,
    SUM(CASE WHEN p.payment_status = 'SUCCESS' THEN 1 ELSE 0 END) AS successful_payments
  FROM payments p
  LEFT JOIN user_events e ON e.transaction_id = p.transaction_id
  LEFT JOIN devices d ON d.device_id = e.device_id
  GROUP BY DATE(p.event_ts), d.device_type, d.os
)
SELECT
  e.metric_date,
  e.device_type,
  e.os,
  e.login_users,
  e.converted_users,
  ROUND(e.converted_users / NULLIF(e.login_users, 0) * 100, 2) AS conversion_rate_pct,
  p.payment_attempts,
  p.successful_payments,
  ROUND(p.successful_payments / NULLIF(p.payment_attempts, 0) * 100, 2) AS payment_success_rate_pct
FROM event_metrics e
LEFT JOIN payment_metrics p
  ON p.metric_date = e.metric_date
 AND p.device_type = e.device_type
 AND p.os = e.os
ORDER BY e.metric_date, e.device_type, e.os;
