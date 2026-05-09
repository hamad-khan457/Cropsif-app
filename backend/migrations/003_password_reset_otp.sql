-- =============================================================================
-- Migration 003: Allow password_reset OTP type
-- =============================================================================
BEGIN;

ALTER TABLE otps DROP CONSTRAINT IF EXISTS otps_otp_type_check;
ALTER TABLE otps ADD CONSTRAINT otps_otp_type_check
  CHECK (otp_type IN ('email_verification','phone_verification','password_reset'));

COMMIT;
