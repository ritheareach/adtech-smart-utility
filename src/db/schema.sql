-- ADTech Smart Utility Management System — Database Schema

CREATE TABLE IF NOT EXISTS users (
  id          SERIAL PRIMARY KEY,
  phone       VARCHAR(20)  UNIQUE NOT NULL,
  name        VARCHAR(100),
  email       VARCHAR(100),
  unit_number VARCHAR(20),
  created_at  TIMESTAMPTZ  DEFAULT NOW()
);

-- Stores one-time passwords sent to users for login
CREATE TABLE IF NOT EXISTS otp_tokens (
  id         SERIAL PRIMARY KEY,
  phone      VARCHAR(20)  NOT NULL,
  code       VARCHAR(6)   NOT NULL,
  expires_at TIMESTAMPTZ  NOT NULL,
  used       BOOLEAN      DEFAULT FALSE,
  created_at TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_phone ON otp_tokens(phone);

-- Utility bills: one row per utility per billing period per user
CREATE TABLE IF NOT EXISTS bills (
  id         VARCHAR(50)    PRIMARY KEY,
  user_id    INTEGER        REFERENCES users(id) ON DELETE CASCADE,
  type       VARCHAR(20)    NOT NULL CHECK (type IN ('Water','Electricity','Gas','Cooling','All')),
  period     VARCHAR(30)    NOT NULL,
  amount     NUMERIC(12, 2) NOT NULL,
  usage      NUMERIC(10, 2) NOT NULL DEFAULT 0,
  unit       VARCHAR(10)    NOT NULL DEFAULT '',
  due_date   DATE           NOT NULL,
  status     VARCHAR(10)    NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid','paid','overdue')),
  created_at TIMESTAMPTZ    DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bills_user_status ON bills(user_id, status);

-- PayWay payment transactions
CREATE TABLE IF NOT EXISTS transactions (
  id              SERIAL PRIMARY KEY,
  user_id         INTEGER        REFERENCES users(id) ON DELETE SET NULL,
  tran_id         VARCHAR(50)    UNIQUE NOT NULL,
  amount          NUMERIC(12, 2) NOT NULL,
  currency        VARCHAR(5)     DEFAULT 'USD',
  payment_option  VARCHAR(30),
  status          VARCHAR(20)    DEFAULT 'pending' CHECK (status IN ('pending','success','failed')),
  payway_response JSONB,
  created_at      TIMESTAMPTZ    DEFAULT NOW(),
  paid_at         TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_tran_id ON transactions(tran_id);

-- Links which bills were settled by which transaction
CREATE TABLE IF NOT EXISTS bill_payments (
  bill_id        VARCHAR(50) REFERENCES bills(id) ON DELETE CASCADE,
  transaction_id INTEGER     REFERENCES transactions(id) ON DELETE CASCADE,
  PRIMARY KEY (bill_id, transaction_id)
);

-- Monthly utility readings (source of truth for usage charts)
CREATE TABLE IF NOT EXISTS usage_readings (
  id         SERIAL         PRIMARY KEY,
  user_id    INTEGER        REFERENCES users(id) ON DELETE CASCADE,
  type       VARCHAR(20)    NOT NULL CHECK (type IN ('Water','Electricity','Gas','Cooling')),
  year       INTEGER        NOT NULL,
  month      INTEGER        NOT NULL CHECK (month BETWEEN 1 AND 12),
  value      NUMERIC(10, 2) NOT NULL,
  unit       VARCHAR(10)    NOT NULL,
  created_at TIMESTAMPTZ    DEFAULT NOW(),
  UNIQUE (user_id, type, year, month)
);

CREATE INDEX IF NOT EXISTS idx_usage_user_year ON usage_readings(user_id, year);

-- Tracks which dynamically-generated notification IDs a user has read
CREATE TABLE IF NOT EXISTS notification_reads (
  user_id  INTEGER      REFERENCES users(id) ON DELETE CASCADE,
  notif_id VARCHAR(150) NOT NULL,
  read_at  TIMESTAMPTZ  DEFAULT NOW(),
  PRIMARY KEY (user_id, notif_id)
);

CREATE INDEX IF NOT EXISTS idx_notif_reads_user ON notification_reads(user_id);
