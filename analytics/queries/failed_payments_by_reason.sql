-- Failed payment attempts by reason and day.

SELECT
  DATE(event_ts) AS metric_date,
  COALESCE(failure_reason, 'UNKNOWN') AS failure_reason,
  payment_method,
  COUNT(*) AS failed_payments,
  ROUND(AVG(processor_latency_ms), 0) AS avg_processor_latency_ms
FROM payments
WHERE payment_status = 'FAILED'
GROUP BY DATE(event_ts), COALESCE(failure_reason, 'UNKNOWN'), payment_method
ORDER BY metric_date, failed_payments DESC;
