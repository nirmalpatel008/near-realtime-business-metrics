-- Daily conversion rate from login to completed purchase.

WITH daily_users AS (
  SELECT
    DATE(event_ts) AS metric_date,
    COUNT(DISTINCT CASE WHEN event_type = 'login' THEN customer_id END) AS login_users,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase_completed' THEN customer_id END) AS converted_users
  FROM user_events
  GROUP BY DATE(event_ts)
)
SELECT
  metric_date,
  login_users,
  converted_users,
  ROUND(converted_users / NULLIF(login_users, 0) * 100, 2) AS conversion_rate_pct
FROM daily_users
ORDER BY metric_date;
