const express = require('express');
const crypto = require('crypto');
const pool = require('../db');
const requireAuth = require('../middleware/auth');

const router = express.Router();

// POST /api/payments/webhook  (no auth — called by PayWay)
// Verifies X_PAYWAY_HMAC_SHA512 signature and updates transaction + bill statuses.
router.post('/webhook', express.urlencoded({ extended: true }), async (req, res) => {
  const receivedSig = req.headers['x_payway_hmac_sha512'];
  const apiKey = process.env.PAYWAY_API_KEY;

  if (apiKey && receivedSig) {
    const sorted = Object.fromEntries(
      Object.entries(req.body).sort(([a], [b]) => a.localeCompare(b))
    );
    const payload = Object.values(sorted).join('');
    const expected = crypto
      .createHmac('sha512', apiKey)
      .update(payload)
      .digest('base64');

    if (expected !== receivedSig) {
      return res.status(401).json({ error: 'Invalid signature' });
    }
  }

  const { tran_id, status } = req.body;
  if (!tran_id) return res.status(400).json({ error: 'tran_id is required' });

  const isSuccess = status?.code === '00' || req.body['status[code]'] === '00';

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const txRes = await client.query(
      `UPDATE transactions
       SET status = $1, payway_response = $2, paid_at = $3
       WHERE tran_id = $4
       RETURNING id`,
      [
        isSuccess ? 'success' : 'failed',
        JSON.stringify(req.body),
        isSuccess ? new Date() : null,
        tran_id,
      ]
    );

    if (txRes.rows.length > 0 && isSuccess) {
      const txId = txRes.rows[0].id;
      await client.query(
        `UPDATE bills SET status = 'paid'
         WHERE id IN (
           SELECT bill_id FROM bill_payments WHERE transaction_id = $1
         )`,
        [txId]
      );
    }

    await client.query('COMMIT');
    res.json({ success: true });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Webhook processing failed' });
  } finally {
    client.release();
  }
});

// POST /api/payments/sandbox/complete
// Sandbox-only: directly marks bills as paid without a real PayWay transaction.
// Blocked in production via NODE_ENV check.
router.post('/sandbox/complete', requireAuth, async (req, res) => {
  if (process.env.NODE_ENV === 'production') {
    return res.status(403).json({ error: 'Not available in production' });
  }
  const { bill_ids = [] } = req.body;
  if (!bill_ids.length) return res.status(400).json({ error: 'bill_ids required' });

  try {
    const result = await pool.query(
      `UPDATE bills SET status = 'paid'
       WHERE id = ANY($1::varchar[]) AND user_id = $2
       RETURNING id`,
      [bill_ids, req.user.userId]
    );
    res.json({ success: true, updated: result.rowCount });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// All routes below require authentication
router.use(requireAuth);

// POST /api/payments
// Body: { tran_id, amount, currency, payment_option, bill_ids: [], paid?: bool }
// Creates (or upserts) a transaction linked to the specified bills.
// Pass paid:true after PayWay confirms success to mark the transaction and bills as paid
// in the same request — used as the client-side fallback when the PayWay webhook
// cannot reach the server (e.g. local dev environment).
router.post('/', async (req, res) => {
  const { tran_id, amount, currency = 'KHR', payment_option, bill_ids = [], paid = false } = req.body;
  if (!tran_id || !amount) return res.status(400).json({ error: 'tran_id and amount are required' });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const txStatus = paid ? 'success' : 'pending';
    const paidAt   = paid ? new Date() : null;

    const txRes = await client.query(
      `INSERT INTO transactions (user_id, tran_id, amount, currency, payment_option, status, paid_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (tran_id) DO UPDATE SET
         amount   = EXCLUDED.amount,
         status   = CASE WHEN transactions.status <> 'success' THEN EXCLUDED.status
                         ELSE transactions.status END,
         paid_at  = COALESCE(transactions.paid_at, EXCLUDED.paid_at)
       RETURNING id`,
      [req.user.userId, tran_id, amount, currency, payment_option, txStatus, paidAt]
    );
    const txId = txRes.rows[0].id;

    for (const billId of bill_ids) {
      await client.query(
        `INSERT INTO bill_payments (bill_id, transaction_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
        [billId, txId]
      );
    }

    if (paid) {
      await client.query(
        `UPDATE bills SET status = 'paid'
         WHERE id IN (SELECT bill_id FROM bill_payments WHERE transaction_id = $1)`,
        [txId]
      );
    }

    await client.query('COMMIT');
    res.status(201).json({ success: true, transactionId: txId });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Failed to create payment' });
  } finally {
    client.release();
  }
});

// GET /api/payments
// Returns payment history for the authenticated user.
router.get('/', async (req, res) => {
  const limit = parseInt(req.query.limit || '20');
  const offset = parseInt(req.query.offset || '0');

  try {
    const result = await pool.query(
      `SELECT t.id, t.tran_id, t.amount, t.currency, t.payment_option,
              t.status, t.created_at, t.paid_at,
              ARRAY_AGG(bp.bill_id) FILTER (WHERE bp.bill_id IS NOT NULL) AS bill_ids
       FROM transactions t
       LEFT JOIN bill_payments bp ON bp.transaction_id = t.id
       WHERE t.user_id = $1
       GROUP BY t.id
       ORDER BY t.created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.user.userId, limit, offset]
    );
    res.json({ payments: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch payments' });
  }
});

// GET /api/payments/:tranId
// Returns a single transaction with its linked bills.
router.get('/:tranId', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT t.id, t.tran_id, t.amount, t.currency, t.payment_option,
              t.status, t.created_at, t.paid_at, t.payway_response
       FROM transactions t
       WHERE t.tran_id = $1 AND t.user_id = $2`,
      [req.params.tranId, req.user.userId]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Transaction not found' });
    res.json({ payment: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch payment' });
  }
});

module.exports = router;
