-- =============================================================================
-- Migration 004: Pending registrations
-- User data is stored here temporarily until OTP is verified.
-- Only after successful OTP verification is a row created in the users table.
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS pending_registrations (
  id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  email          VARCHAR(255) NOT NULL UNIQUE,
  phone          VARCHAR(20)  UNIQUE,
  cnic           VARCHAR(15)  UNIQUE,
  full_name      VARCHAR(100) NOT NULL,
  password_hash  TEXT         NOT NULL,
  role           VARCHAR(20)  NOT NULL CHECK (role IN ('landowner','manager','worker','admin')),
  otp_code       VARCHAR(6)   NOT NULL,
  otp_expires_at TIMESTAMPTZ  NOT NULL,
  resend_count   SMALLINT     NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pending_reg_email ON pending_registrations (email);
CREATE INDEX IF NOT EXISTS idx_pending_reg_phone ON pending_registrations (phone);
CREATE INDEX IF NOT EXISTS idx_pending_reg_cnic  ON pending_registrations (cnic);

COMMIT;
