-- Daily Active Users by day.
-- Compatible with the portfolio synthetic schema in data/synthetic-schema.sql.

SELECT
  DATE(event_ts) AS metric_date,
  COUNT(DISTINCT customer_id) AS daily_active_users
FROM user_events
WHERE event_type IN ('login', 'payment_initiated', 'purchase_completed')
GROUP BY DATE(event_ts)
ORDER BY metric_date;
