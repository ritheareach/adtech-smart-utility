const express = require('express');
const pool = require('../db');
const requireAuth = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

// GET /api/usage/summary?period=week|month
// Returns usage totals and % change vs. previous period.
router.get('/summary', async (req, res) => {
  const period = req.query.period === 'week' ? 'week' : 'month';
  const userId = req.user.userId;

  try {
    // Current period totals
    const current = await pool.query(
      `SELECT type, SUM(value) AS value, unit
       FROM usage_readings
       WHERE user_id = $1
         AND (year * 100 + month) = (
           SELECT MAX(year * 100 + month) FROM usage_readings WHERE user_id = $1
         )
       GROUP BY type, unit`,
      [userId]
    );

    // Previous period (month before the latest)
    const previous = await pool.query(
      `WITH ranked AS (
         SELECT DISTINCT year, month,
                ROW_NUMBER() OVER (ORDER BY year DESC, month DESC) AS rn
         FROM usage_readings WHERE user_id = $1
       )
       SELECT r.type, SUM(r.value) AS value
       FROM usage_readings r
       JOIN ranked k ON r.year = k.year AND r.month = k.month
       WHERE r.user_id = $1 AND k.rn = 2
       GROUP BY r.type`,
      [userId]
    );

    const prevMap = {};
    for (const row of previous.rows) prevMap[row.type] = parseFloat(row.value);

    const summaries = current.rows.map((row) => {
      const curr = parseFloat(row.value);
      const prev = prevMap[row.type] ?? curr;
      const change = prev === 0 ? 0 : Math.abs(((curr - prev) / prev) * 100);
      return {
        type: row.type,
        value: curr,
        unit: row.unit,
        changePercent: parseFloat(change.toFixed(1)),
        isUp: curr >= prev,
      };
    });

    res.json({ period, summaries });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch usage summary' });
  }
});

// GET /api/usage/monthly?year=2025
// Returns monthly breakdown for all utility types for the given year.
router.get('/monthly', async (req, res) => {
  const year = parseInt(req.query.year || new Date().getFullYear());
  const userId = req.user.userId;

  const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  try {
    const result = await pool.query(
      `SELECT type, month, value, unit
       FROM usage_readings
       WHERE user_id = $1 AND year = $2
       ORDER BY month ASC`,
      [userId, year]
    );

    // Build month-indexed map
    const byMonth = {};
    for (let m = 1; m <= 12; m++) {
      byMonth[m] = { month: MONTHS[m - 1], water: 0, electricity: 0, gas: 0, cooling: 0 };
    }
    for (const row of result.rows) {
      const key = row.type.toLowerCase();
      byMonth[row.month][key] = parseFloat(row.value);
    }

    res.json({ year, monthly: Object.values(byMonth) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch monthly usage' });
  }
});

module.exports = router;
