-- Daily reconciliation checks for finance-style facts.
-- Run on source and target, then compare outputs.

SELECT
  DATE(event_ts) AS metric_date,
  COUNT(*) AS transaction_count,
  ROUND(SUM(amount), 2) AS gross_transaction_value,
  SUM(CASE WHEN transaction_status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_transactions,
  SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) AS failed_transactions
FROM transactions
GROUP BY DATE(event_ts)
ORDER BY metric_date;
