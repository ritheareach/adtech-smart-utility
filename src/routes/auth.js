const express = require('express');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const requireAuth = require('../middleware/auth');

const router = express.Router();

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

// POST /api/auth/login
// Body: { phone: "012345678" }
// Creates an OTP for the phone number and returns it (dev mode) or sends via SMS (prod).
router.post('/login', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'phone is required' });

  const normalized = phone.replace(/\s+/g, '');
  const code = generateOtp();
  const expiresAt = new Date(Date.now() + parseInt(process.env.OTP_EXPIRES_MINUTES || '5') * 60 * 1000);

  try {
    // Invalidate any previous unused OTPs for this phone
    await pool.query(
      `UPDATE otp_tokens SET used = TRUE WHERE phone = $1 AND used = FALSE`,
      [normalized]
    );

    await pool.query(
      `INSERT INTO otp_tokens (phone, code, expires_at) VALUES ($1, $2, $3)`,
      [normalized, code, expiresAt]
    );

    // In production: integrate an SMS gateway here and remove `otp` from the response.
    const devMode = process.env.OTP_DEV_MODE === 'true';
    console.log(`OTP for ${normalized}: ${code}`);

    res.json({
      success: true,
      message: 'OTP sent',
      ...(devMode && { otp: code }),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to generate OTP' });
  }
});

// POST /api/auth/verify-otp
// Body: { phone: "012345678", code: "123456" }
// Verifies the OTP and returns a JWT + user profile.
router.post('/verify-otp', async (req, res) => {
  const { phone, code } = req.body;
  if (!phone || !code) return res.status(400).json({ error: 'phone and code are required' });

  const normalized = phone.replace(/\s+/g, '');

  try {
    const otpRes = await pool.query(
      `SELECT * FROM otp_tokens
       WHERE phone = $1 AND code = $2 AND used = FALSE AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
      [normalized, code]
    );

    if (otpRes.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid or expired OTP' });
    }

    // Mark OTP as used
    await pool.query(`UPDATE otp_tokens SET used = TRUE WHERE id = $1`, [otpRes.rows[0].id]);

    // Upsert user
    const userRes = await pool.query(
      `INSERT INTO users (phone) VALUES ($1)
       ON CONFLICT (phone) DO UPDATE SET phone = EXCLUDED.phone
       RETURNING *`,
      [normalized]
    );
    const user = userRes.rows[0];

    const token = jwt.sign(
      { userId: user.id, phone: user.phone },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        unitNumber: user.unit_number,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Verification failed' });
  }
});

// GET /api/auth/me
router.get('/me', requireAuth, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, phone, name, email, unit_number FROM users WHERE id = $1',
      [req.user.userId]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    const u = result.rows[0];
    res.json({ id: u.id, phone: u.phone, name: u.name, email: u.email, unitNumber: u.unit_number });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

module.exports = router;
