const express = require('express');
const pool = require('../db');
const requireAuth = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

function fmtKhr(amount) {
  const n = Math.round(parseFloat(amount));
  return n >= 1000
    ? `${Math.floor(n / 1000)},${String(n % 1000).padStart(3, '0')}`
    : String(n);
}

async function buildNotifications(userId) {
  const readResult = await pool.query(
    'SELECT notif_id FROM notification_reads WHERE user_id = $1',
    [userId]
  );
  const readIds = new Set(readResult.rows.map(r => r.notif_id));

  const notifications = [];

  // ── 1. Payment due / overdue — one per unpaid bill ───────────────────────
  //    Disappears automatically once the bill is paid.
  const unpaid = await pool.query(
    `SELECT id, type, period, amount, due_date, status
     FROM bills
     WHERE user_id = $1 AND status IN ('unpaid', 'overdue')
     ORDER BY due_date ASC`,
    [userId]
  );

  for (const bill of unpaid.rows) {
    const notifId = `notif-due-${bill.id}`;
    const dueDate = new Date(bill.due_date);
    // Bill is issued on the 1st of the due-date month; alert fires 5 days later
    const issuedAt  = new Date(dueDate.getFullYear(), dueDate.getMonth(), 1);
    const alertAt   = new Date(issuedAt.getTime() + 5 * 24 * 60 * 60 * 1000);

    const daysLeft  = Math.floor((dueDate - Date.now()) / 86400000);
    const isOverdue = daysLeft < 0;

    // Don't surface the notification before its alert date (unless already overdue)
    if (!isOverdue && Date.now() < alertAt.getTime()) continue;

    const amt = fmtKhr(bill.amount);
    notifications.push({
      id: notifId,
      type: isOverdue ? 'payment_overdue' : 'payment_due',
      title: isOverdue ? 'Payment Overdue' : 'Payment Due Soon',
      body: isOverdue
        ? `Your ${bill.period} ${bill.type} bill of ៛${amt} is overdue.`
        : `Your ${bill.period} ${bill.type} bill of ៛${amt} is due in ${daysLeft} day${daysLeft === 1 ? '' : 's'}.`,
      created_at: alertAt.toISOString(),
      read: readIds.has(notifId),
    });
  }

  // ── 2. Bill generated — for the latest billing period (always 1) ─────────
  const latestPeriod = await pool.query(
    `SELECT period, SUM(amount) AS total, MAX(due_date) AS due_date
     FROM bills WHERE user_id = $1
     GROUP BY period ORDER BY MAX(due_date) DESC LIMIT 1`,
    [userId]
  );

  if (latestPeriod.rows.length > 0) {
    const row = latestPeriod.rows[0];
    const notifId = `notif-new-${row.period.replace(/\s/g, '-')}`;
    const dueDate = new Date(row.due_date);
    // Bills are issued on the 1st of the due-date month (e.g. May 2026 bill → issued Jun 1)
    const issuedAt = new Date(dueDate.getFullYear(), dueDate.getMonth(), 1);
    // Cap at today in case the issue date is in the future
    const createdAt = issuedAt > new Date() ? new Date() : issuedAt;
    notifications.push({
      id: notifId,
      type: 'bill_generated',
      title: 'New Bill Generated',
      body: `Your ${row.period} utility bill has been generated. Total: ៛${fmtKhr(row.total)}.`,
      created_at: createdAt.toISOString(),
      read: readIds.has(notifId),
    });
  }

  // ── 3. Payment confirmed — one per paid bill (most recent 8) ─────────────
  //    Appears as soon as a bill is marked paid, so users get immediate
  //    confirmation per-bill rather than waiting for a full period to close.
  // Use LEAST(due_date, CURRENT_DATE) so bills with future due dates (e.g. just
  // paid via sandbox before they were technically due) don't produce a future
  // created_at, which the client would display as a negative relative time.
  const paidBills = await pool.query(
    `SELECT id, type, period, amount,
            LEAST(due_date, CURRENT_DATE) AS paid_date
     FROM bills
     WHERE user_id = $1 AND status = 'paid'
     ORDER BY due_date DESC
     LIMIT 8`,
    [userId]
  );

  for (const bill of paidBills.rows) {
    const notifId = `notif-paid-${bill.id}`;
    notifications.push({
      id: notifId,
      type: 'payment_confirmed',
      title: 'Payment Confirmed',
      body: `Your ${bill.period} ${bill.type} bill of ៛${fmtKhr(bill.amount)} was paid successfully.`,
      created_at: new Date(bill.paid_date).toISOString(),
      read: readIds.has(notifId),
    });
  }

  // ── 4. Usage alerts — per utility type when shift ≥ 5% month-over-month ──
  const usageRows = await pool.query(
    `SELECT type, year, month, value, unit
     FROM usage_readings
     WHERE user_id = $1
     ORDER BY year DESC, month DESC
     LIMIT 8`,
    [userId]
  );

  const byType = {};
  for (const r of usageRows.rows) {
    (byType[r.type] = byType[r.type] || []).push(r);
  }

  for (const [type, readings] of Object.entries(byType)) {
    if (readings.length < 2) continue;
    const curr = readings[0];
    const prev = readings[1];
    const pct = ((parseFloat(curr.value) - parseFloat(prev.value)) / parseFloat(prev.value)) * 100;
    if (Math.abs(pct) < 5) continue;

    const notifId = `notif-usage-${type}-${curr.year}-${curr.month}`;
    const isHigh = pct > 0;
    notifications.push({
      id: notifId,
      type: isHigh ? 'usage_high' : 'usage_low',
      title: `${isHigh ? 'High' : 'Lower'} ${type} Usage`,
      body: `${type} usage is ${Math.abs(pct).toFixed(1)}% ${isHigh ? 'higher' : 'lower'} than last month (${parseFloat(curr.value).toFixed(1)} ${curr.unit}).`,
      created_at: new Date(curr.year, curr.month - 1, 15).toISOString(),
      read: readIds.has(notifId),
    });
  }

  // Unread first, then newest
  notifications.sort((a, b) => {
    if (a.read !== b.read) return a.read ? 1 : -1;
    return new Date(b.created_at) - new Date(a.created_at);
  });

  return notifications;
}

// GET /api/notifications
router.get('/', async (req, res) => {
  try {
    const notifications = await buildNotifications(req.user.userId);
    res.json({ notifications });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// PATCH /api/notifications/read-all  — must be registered before /:id
router.patch('/read-all', async (req, res) => {
  const { ids } = req.body;
  if (!Array.isArray(ids) || ids.length === 0) return res.json({ updated: 0 });
  try {
    for (const id of ids) {
      await pool.query(
        `INSERT INTO notification_reads (user_id, notif_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
        [req.user.userId, id]
      );
    }
    res.json({ updated: ids.length });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to mark all read' });
  }
});

// PATCH /api/notifications/:id/read
router.patch('/:id/read', async (req, res) => {
  try {
    await pool.query(
      `INSERT INTO notification_reads (user_id, notif_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [req.user.userId, req.params.id]
    );
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to mark read' });
  }
});

module.exports = router;
