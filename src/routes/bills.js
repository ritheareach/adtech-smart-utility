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

// GET /api/bills/monthly-totals
// Returns the last 12 completed months (rolling window) with labels and totals.
// due_date is the 6th of the month AFTER the billing month, so subtract 1 month to get consumption month.
router.get('/monthly-totals', async (req, res) => {
  const MONTH_ABBR = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  try {
    const result = await pool.query(
      `SELECT
         EXTRACT(YEAR  FROM due_date - INTERVAL '1 month')::int AS yr,
         EXTRACT(MONTH FROM due_date - INTERVAL '1 month')::int AS mo,
         SUM(amount) AS total
       FROM bills
       WHERE user_id = $1
       GROUP BY yr, mo`,
      [req.user.userId]
    );

    const totalsMap = {};
    for (const row of result.rows) {
      totalsMap[row.yr * 100 + row.mo] = parseFloat(row.total);
    }

    // Last 12 completed months ending at the previous month
    const now = new Date();
    const points = [];
    for (let i = 11; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - 1 - i, 1);
      const y = d.getFullYear();
      const m = d.getMonth() + 1;
      points.push({ label: MONTH_ABBR[m - 1], total: totalsMap[y * 100 + m] ?? 0 });
    }

    res.json({
      months: points.map(p => p.label),
      totals: points.map(p => p.total),
    });
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
