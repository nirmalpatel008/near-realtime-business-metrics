-- DAU and payment success by city.

SELECT
  DATE(e.event_ts) AS metric_date,
  r.country,
  r.state,
  r.city,
  COUNT(DISTINCT e.customer_id) AS active_users,
  COUNT(p.payment_id) AS payment_attempts,
  SUM(CASE WHEN p.payment_status = 'SUCCESS' THEN 1 ELSE 0 END) AS successful_payments,
  ROUND(SUM(CASE WHEN p.payment_status = 'SUCCESS' THEN 1 ELSE 0 END) / NULLIF(COUNT(p.payment_id), 0) * 100, 2) AS payment_success_rate_pct
FROM user_events e
JOIN customers c ON c.customer_id = e.customer_id
JOIN regions r ON r.region_id = c.region_id
LEFT JOIN payments p
  ON p.customer_id = e.customer_id
 AND DATE(p.event_ts) = DATE(e.event_ts)
WHERE e.event_type IN ('login', 'payment_initiated', 'purchase_completed')
GROUP BY DATE(e.event_ts), r.country, r.state, r.city
ORDER BY metric_date, active_users DESC;
