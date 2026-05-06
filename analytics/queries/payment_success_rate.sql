-- Daily payment success rate.

SELECT
  DATE(event_ts) AS metric_date,
  COUNT(*) AS payment_attempts,
  SUM(CASE WHEN payment_status = 'SUCCESS' THEN 1 ELSE 0 END) AS successful_payments,
  ROUND(SUM(CASE WHEN payment_status = 'SUCCESS' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS success_rate_pct
FROM payments
GROUP BY DATE(event_ts)
ORDER BY metric_date;
