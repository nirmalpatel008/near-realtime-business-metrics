-- ACT 4: prove "Data Pipeline" integrity.
-- Multi-table transaction: new order for an existing customer debits that
-- customer's account balance atomically. DMS preserves transaction boundaries,
-- so both rows appear on target together.

USE demo;

START TRANSACTION;

SET @cust   := 42;
SET @amount := 1999.00;
SET @ts     := NOW(6);

INSERT INTO orders (customer_id, amount, status, event_ts)
VALUES (@cust, @amount, 'TXN', @ts);

UPDATE accounts
   SET balance = balance - @amount
 WHERE customer_id = @cust;

COMMIT;

-- What we just wrote on source
SELECT 'source: order' AS side, id, customer_id, amount, status, event_ts
  FROM orders WHERE customer_id=@cust AND status='TXN' AND event_ts=@ts;

SELECT 'source: account' AS side, customer_id, balance, updated_at
  FROM accounts WHERE customer_id=@cust;
