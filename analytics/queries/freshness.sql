-- Dashboard freshness in seconds.

SELECT
  'user_events' AS table_name,
  MAX(event_ts) AS latest_event_ts,
  TIMESTAMPDIFF(SECOND, MAX(event_ts), NOW()) AS freshness_sec
FROM user_events
UNION ALL
SELECT
  'transactions',
  MAX(event_ts),
  TIMESTAMPDIFF(SECOND, MAX(event_ts), NOW())
FROM transactions
UNION ALL
SELECT
  'payments',
  MAX(event_ts),
  TIMESTAMPDIFF(SECOND, MAX(event_ts), NOW())
FROM payments;
