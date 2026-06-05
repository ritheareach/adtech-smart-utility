require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes     = require('./routes/auth');
const billsRoutes    = require('./routes/bills');
const usageRoutes    = require('./routes/usage');
const paymentsRoutes = require('./routes/payments');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (_, res) => res.json({ status: 'ok', ts: new Date() }));

app.use('/api/auth',     authRoutes);
app.use('/api/bills',    billsRoutes);
app.use('/api/usage',    usageRoutes);
app.use('/api/payments', paymentsRoutes);

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`ADTech API running on http://localhost:${PORT}`);
});
