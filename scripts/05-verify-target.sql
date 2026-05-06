-- Verify on TARGET after ACT 4: both sides of the transaction landed together.

USE demo;

SELECT 'target: order' AS side, id, customer_id, amount, status, event_ts
  FROM orders WHERE customer_id=42 AND status='TXN'
  ORDER BY id DESC LIMIT 1;

SELECT 'target: account' AS side, customer_id, balance, updated_at
  FROM accounts WHERE customer_id=42;

SELECT 'customers' AS t, COUNT(*) AS rows_ FROM customers
UNION ALL SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL SELECT 'orders',   COUNT(*) FROM orders;
