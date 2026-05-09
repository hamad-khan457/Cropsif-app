-- =============================================================================
-- Migration 001: Module 1 — User Management & Authentication
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name        VARCHAR(100)  NOT NULL,
  email            VARCHAR(255)  NOT NULL UNIQUE,
  phone            VARCHAR(20)   UNIQUE,
  cnic             VARCHAR(15)   UNIQUE,
  password_hash    TEXT          NOT NULL,
  role             VARCHAR(20)   NOT NULL CHECK (role IN ('landowner','manager','worker','admin')),
  is_verified      BOOLEAN       NOT NULL DEFAULT FALSE,
  is_active        BOOLEAN       NOT NULL DEFAULT TRUE,
  is_locked        BOOLEAN       NOT NULL DEFAULT FALSE,
  failed_attempts  SMALLINT      NOT NULL DEFAULT 0,
  locked_until     TIMESTAMPTZ,
  created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users (phone);
CREATE INDEX IF NOT EXISTS idx_users_role  ON users (role);

-- ---------------------------------------------------------------------------
-- otps
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS otps (
  id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  otp_code     VARCHAR(6)   NOT NULL,
  otp_type     VARCHAR(30)  NOT NULL CHECK (otp_type IN ('email_verification','phone_verification')),
  is_used      BOOLEAN      NOT NULL DEFAULT FALSE,
  attempts     SMALLINT     NOT NULL DEFAULT 0,
  expires_at   TIMESTAMPTZ  NOT NULL,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otps_user_id ON otps (user_id);

-- ---------------------------------------------------------------------------
-- refresh_tokens
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  token_hash   TEXT         NOT NULL UNIQUE,
  device_info  TEXT,
  ip_address   VARCHAR(45),
  is_revoked   BOOLEAN      NOT NULL DEFAULT FALSE,
  expires_at   TIMESTAMPTZ  NOT NULL,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id    ON refresh_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash ON refresh_tokens (token_hash);

-- ---------------------------------------------------------------------------
-- password_resets
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS password_resets (
  id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  token_hash TEXT         NOT NULL UNIQUE,
  is_used    BOOLEAN      NOT NULL DEFAULT FALSE,
  expires_at TIMESTAMPTZ  NOT NULL,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_password_resets_token_hash ON password_resets (token_hash);

-- ---------------------------------------------------------------------------
-- notification_preferences
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notification_preferences (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID        NOT NULL UNIQUE REFERENCES users (id) ON DELETE CASCADE,
  push_alerts       BOOLEAN     NOT NULL DEFAULT TRUE,
  email_digest      BOOLEAN     NOT NULL DEFAULT TRUE,
  sms_alerts        BOOLEAN     NOT NULL DEFAULT FALSE,
  quiet_hours_start TIME,
  quiet_hours_end   TIME,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMIT;