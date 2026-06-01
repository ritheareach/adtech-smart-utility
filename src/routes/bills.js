const express = require('express');
const pool = require('../db');
const requireAuth = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

const SELECT_COLS = `
  id, type, period, amount, usage, unit,
  TO_CHAR(due_date, 'Mon DD, YYYY') AS due_date_fmt, status`;

function mapBill(row) {
  return { ...row, due_date: row.due_date_fmt, due_date_fmt: undefined };
}

// GET /api/bills
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT ${SELECT_COLS}
       FROM bills
       WHERE user_id = $1 AND status IN ('unpaid', 'overdue')
       ORDER BY bills.due_date ASC`,
      [req.user.userId]
    );
    res.json({ bills: result.rows.map(mapBill) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch bills' });
  }
});

// GET /api/bills/history — paid bills, newest first
router.get('/history', async (req, res) => {
  const limit  = parseInt(req.query.limit  || '100');
  const offset = parseInt(req.query.offset || '0');
  try {
    const result = await pool.query(
      `SELECT ${SELECT_COLS}
       FROM bills
       WHERE user_id = $1 AND status = 'paid'
       ORDER BY bills.due_date DESC
       LIMIT $2 OFFSET $3`,
      [req.user.userId, limit, offset]
    );
    res.json({ bills: result.rows.map(mapBill) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch bill history' });
  }
});

// GET /api/bills/records — all bills, newest first (analytics)
router.get('/records', async (req, res) => {
  const limit  = parseInt(req.query.limit  || '100');
  const offset = parseInt(req.query.offset || '0');
  try {
    const result = await pool.query(
      `SELECT ${SELECT_COLS}
       FROM bills
       WHERE user_id = $1
       ORDER BY bills.due_date DESC, bills.type ASC
       LIMIT $2 OFFSET $3`,
      [req.user.userId, limit, offset]
    );
    res.json({ bills: result.rows.map(mapBill) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch bill records' });
  }
});

// GET /api/bills/monthly-totals?year=YYYY
router.get('/monthly-totals', async (req, res) => {
  const year = parseInt(req.query.year || new Date().getFullYear());
  try {
    const result = await pool.query(
      `SELECT EXTRACT(MONTH FROM due_date)::int AS month, SUM(amount) AS total
       FROM bills
       WHERE user_id = $1 AND EXTRACT(YEAR FROM due_date) = $2
       GROUP BY month ORDER BY month`,
      [req.user.userId, year]
    );
    const totals = Array(12).fill(0);
    for (const row of result.rows) totals[row.month - 1] = parseFloat(row.total);
    res.json({ year, totals });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch monthly totals' });
  }
});

// GET /api/bills/:id
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT ${SELECT_COLS}
       FROM bills WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.user.userId]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Bill not found' });
    res.json({ bill: mapBill(result.rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch bill' });
  }
});

module.exports = router;
