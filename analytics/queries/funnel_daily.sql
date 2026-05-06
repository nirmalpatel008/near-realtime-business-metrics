-- Daily funnel counts by distinct sessions.

SELECT
  DATE(event_ts) AS metric_date,
  COUNT(DISTINCT CASE WHEN event_type = 'login' THEN session_id END) AS login_sessions,
  COUNT(DISTINCT CASE WHEN event_type = 'view_merchant' THEN session_id END) AS merchant_view_sessions,
  COUNT(DISTINCT CASE WHEN event_type = 'payment_initiated' THEN session_id END) AS payment_started_sessions,
  COUNT(DISTINCT CASE WHEN event_type = 'payment_success' THEN session_id END) AS payment_success_sessions,
  COUNT(DISTINCT CASE WHEN event_type = 'purchase_completed' THEN session_id END) AS purchase_sessions
FROM user_events
GROUP BY DATE(event_ts)
ORDER BY metric_date;
