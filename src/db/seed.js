// Generates 12 months of realistic randomised utility data ending at the current month.
const pool = require('./index');

// Seeded random — same run always produces the same data
function seededRand(seed) {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) & 0xffffffff;
    return (s >>> 0) / 0xffffffff;
  };
}

function randBetween(rng, min, max) {
  return +(min + rng() * (max - min)).toFixed(2);
}

// Month names for IDs
const MONTH_ABBR = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];

// Seasonal multipliers per month (0-indexed) — simulates Cambodia climate
//                     J     F     M     A     M     J     J     A     S     O     N     D
const WATER_MULT  = [0.88, 0.85, 0.90, 0.95, 1.10, 1.18, 1.25, 1.20, 1.15, 1.05, 0.92, 0.88];
const ELEC_MULT   = [0.90, 0.92, 1.05, 1.18, 1.22, 1.15, 1.08, 1.05, 1.00, 0.95, 0.90, 0.88];
const GAS_MULT    = [1.10, 1.08, 1.02, 0.95, 0.88, 0.85, 0.85, 0.88, 0.92, 0.98, 1.05, 1.12];
const COOL_MULT   = [0.88, 0.90, 1.05, 1.20, 1.25, 1.18, 1.12, 1.10, 1.05, 0.98, 0.90, 0.85];

// KHR unit prices
const PRICE = {
  Water:       1500,  // KHR per m³
  Electricity: 1500,  // KHR per kWh
  Gas:         1500,  // KHR per L
  Cooling:     140,   // KHR per kWh
};

// Base usages
const BASE = {
  Water:       { min: 20, max: 30, unit: 'm³'  },
  Electricity: { min: 105, max: 135, unit: 'kWh' },
  Gas:         { min: 13, max: 20, unit: 'L'   },
  Cooling:     { min: 185, max: 235, unit: 'kWh' },
};

const TYPES = ['Water', 'Electricity', 'Gas', 'Cooling'];

function typeCode(type) {
  return { Water: 'WTR', Electricity: 'ELE', Gas: 'GAS', Cooling: 'COL' }[type];
}

function monthMult(type, monthIdx) {
  return { Water: WATER_MULT, Electricity: ELEC_MULT, Gas: GAS_MULT, Cooling: COOL_MULT }[type][monthIdx];
}

async function seed() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // ── Upsert demo user ───────────────────────────────────────────────────
    const userRes = await client.query(`
      INSERT INTO users (phone, name, email, unit_number)
      VALUES ('012345678', 'Demo User', 'demo@adtech.com', 'A-15')
      ON CONFLICT (phone) DO UPDATE
        SET name = EXCLUDED.name, email = EXCLUDED.email, unit_number = EXCLUDED.unit_number
      RETURNING id
    `);
    const userId = userRes.rows[0].id;

    // ── Clear existing data for this user ──────────────────────────────────
    await client.query(`DELETE FROM bill_payments WHERE bill_id IN (SELECT id FROM bills WHERE user_id = $1)`, [userId]);
    await client.query(`DELETE FROM bills WHERE user_id = $1`, [userId]);
    await client.query(`DELETE FROM usage_readings WHERE user_id = $1`, [userId]);

    // ── Build months from Jan 2025 up to (but not including) current month ──
    // Bills are generated after month-end, so current month has no data yet.
    const now    = new Date();
    const cutoff = new Date(now.getFullYear(), now.getMonth(), 1); // first day of current month
    const start  = new Date(2025, 0, 1); // Jan 2025
    const months = [];
    for (let d = new Date(start); d < cutoff; d.setMonth(d.getMonth() + 1)) {
      months.push({ year: d.getFullYear(), month: d.getMonth() + 1 });
    }

    // Last completed month = unpaid (bill issued, not yet paid), rest = paid
    const UNPAID_COUNT = 1;

    let billSeq = 1;
    const rng = seededRand(42);

    for (let mi = 0; mi < months.length; mi++) {
      const { year, month } = months[mi];
      const mIdx   = month - 1;                // 0-indexed for multipliers
      const isUnpaid = mi >= months.length - UNPAID_COUNT;
      const status = isUnpaid ? 'unpaid' : 'paid';

      // Due date = 6th of the following month
      const dueDate = new Date(year, month, 6); // month here is already +1 from month index
      const yy = String(year).slice(2);
      const mm = String(month).padStart(2, '0');
      const periodLabel = `${new Date(year, mIdx).toLocaleString('en', { month: 'short' })} ${year}`;

      for (const type of TYPES) {
        const base  = BASE[type];
        const mult  = monthMult(type, mIdx);
        const usage = randBetween(rng, base.min * mult, base.max * mult);
        const amount = Math.round(usage * PRICE[type] / 100) * 100; // round to nearest 100 KHR
        const id    = `${typeCode(type)}-${yy}${mm}-${String(billSeq).padStart(5, '0')}`;
        billSeq++;

        await client.query(`
          INSERT INTO bills (id, user_id, type, period, amount, usage, unit, due_date, status)
          VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
          ON CONFLICT (id) DO UPDATE
            SET amount = EXCLUDED.amount, usage = EXCLUDED.usage, status = EXCLUDED.status
        `, [id, userId, type, periodLabel, amount, usage, base.unit, dueDate.toISOString().split('T')[0], status]);

        // Usage reading
        await client.query(`
          INSERT INTO usage_readings (user_id, type, year, month, value, unit)
          VALUES ($1,$2,$3,$4,$5,$6)
          ON CONFLICT (user_id, type, year, month) DO UPDATE SET value = EXCLUDED.value
        `, [userId, type, year, month, usage, base.unit]);
      }
    }

    await client.query('COMMIT');

    const totalBills = months.length * TYPES.length;
    console.log(`✓ Seeded ${months.length} months × ${TYPES.length} utilities = ${totalBills} bills`);
    console.log(`  Months: ${months[0].year}/${months[0].month} → ${months[months.length-1].year}/${months[months.length-1].month}`);
    console.log(`  Unpaid: last ${UNPAID_COUNT} month(s)`);
    console.log(`  User id: ${userId}`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Seed failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
