const { query, transaction } = require('../../config/database');

// ─── Users ────────────────────────────────────────────────────────────────────

async function createUser({ fullName, email, phone, cnic, passwordHash, role }) {
  const { rows } = await query(
    `INSERT INTO users (full_name, email, phone, cnic, password_hash, role)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING id, full_name, email, phone, cnic, role, is_verified, created_at`,
    [fullName, email, phone, cnic, passwordHash, role],
  );
  return rows[0];
}

async function findUserByEmail(email) {
  const { rows } = await query(
    `SELECT id, full_name, email, phone, cnic, password_hash, role,
            is_verified, is_active, is_locked, locked_until,
            failed_attempts, created_at
     FROM users WHERE email = $1`,
    [email],
  );
  return rows[0] || null;
}

async function findUserByCnic(cnic) {
  const { rows } = await query(
    `SELECT id FROM users WHERE cnic = $1`,
    [cnic],
  );
  return rows[0] || null;
}

async function findUserByPhone(phone) {
  const { rows } = await query(
    `SELECT id, full_name, email, phone, cnic, password_hash, role,
            is_verified, is_active, is_locked, locked_until,
            failed_attempts, created_at
     FROM users WHERE phone = $1`,
    [phone],
  );
  return rows[0] || null;
}

async function findUserById(id) {
  const { rows } = await query(
    `SELECT id, full_name, email, phone, cnic, role,
            is_verified, is_active, created_at
     FROM users WHERE id = $1`,
    [id],
  );
  return rows[0] || null;
}

async function markUserVerified(userId) {
  await query(
    `UPDATE users SET is_verified = TRUE, updated_at = NOW() WHERE id = $1`,
    [userId],
  );
}

async function incrementFailedAttempts(userId) {
  await query(
    `UPDATE users SET failed_attempts = failed_attempts + 1, updated_at = NOW()
     WHERE id = $1`,
    [userId],
  );
}

async function lockUser(userId, lockUntil) {
  await query(
    `UPDATE users SET is_locked = TRUE, locked_until = $2, updated_at = NOW()
     WHERE id = $1`,
    [userId, lockUntil],
  );
}

async function resetFailedAttempts(userId) {
  await query(
    `UPDATE users
     SET failed_attempts = 0, is_locked = FALSE, locked_until = NULL, updated_at = NOW()
     WHERE id = $1`,
    [userId],
  );
}

async function updatePassword(userId, passwordHash) {
  await query(
    `UPDATE users SET password_hash = $2, updated_at = NOW() WHERE id = $1`,
    [userId, passwordHash],
  );
}

async function deactivateUser(userId) {
  await query(
    `UPDATE users SET is_active = FALSE, updated_at = NOW() WHERE id = $1`,
    [userId],
  );
}

// ─── Pending Registrations ────────────────────────────────────────────────────
// User data lives here until OTP is verified; then it moves to the users table.

async function upsertPendingRegistration({ fullName, email, phone, cnic, passwordHash, role, otpCode, otpExpiresAt }) {
  const { rows } = await query(
    `INSERT INTO pending_registrations
       (email, phone, cnic, full_name, password_hash, role, otp_code, otp_expires_at, resend_count)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 0)
     ON CONFLICT (email) DO UPDATE
       SET phone         = EXCLUDED.phone,
           cnic          = EXCLUDED.cnic,
           full_name     = EXCLUDED.full_name,
           password_hash = EXCLUDED.password_hash,
           role          = EXCLUDED.role,
           otp_code      = EXCLUDED.otp_code,
           otp_expires_at = EXCLUDED.otp_expires_at,
           resend_count  = 0,
           created_at    = NOW()
     RETURNING *`,
    [email, phone, cnic, fullName, passwordHash, role, otpCode, otpExpiresAt],
  );
  return rows[0];
}

async function findPendingByEmail(email) {
  const { rows } = await query(
    `SELECT * FROM pending_registrations WHERE email = $1`,
    [email],
  );
  return rows[0] || null;
}

async function findPendingByPhone(phone) {
  const { rows } = await query(
    `SELECT id FROM pending_registrations WHERE phone = $1`,
    [phone],
  );
  return rows[0] || null;
}

async function findPendingByCnic(cnic) {
  const { rows } = await query(
    `SELECT id FROM pending_registrations WHERE cnic = $1`,
    [cnic],
  );
  return rows[0] || null;
}

async function updatePendingOtp(email, otpCode, otpExpiresAt) {
  await query(
    `UPDATE pending_registrations
     SET otp_code = $2, otp_expires_at = $3, resend_count = resend_count + 1
     WHERE email = $1`,
    [email, otpCode, otpExpiresAt],
  );
}

async function deletePendingByEmail(email) {
  await query(`DELETE FROM pending_registrations WHERE email = $1`, [email]);
}

// ─── OTPs ─────────────────────────────────────────────────────────────────────

async function createOtp({ userId, otpCode, otpType, expiresAt }) {
  // Invalidate existing unused OTPs of the same type
  await query(
    `UPDATE otps SET is_used = TRUE WHERE user_id = $1 AND otp_type = $2 AND is_used = FALSE`,
    [userId, otpType],
  );

  const { rows } = await query(
    `INSERT INTO otps (user_id, otp_code, otp_type, expires_at)
     VALUES ($1, $2, $3, $4)
     RETURNING id, otp_code, expires_at`,
    [userId, otpCode, otpType, expiresAt],
  );
  return rows[0];
}

async function findValidOtp(userId, otpType) {
  const { rows } = await query(
    `SELECT id, otp_code, expires_at, attempts
     FROM otps
     WHERE user_id = $1
       AND otp_type = $2
       AND is_used = FALSE
       AND expires_at > NOW()
     ORDER BY created_at DESC
     LIMIT 1`,
    [userId, otpType],
  );
  return rows[0] || null;
}

async function markOtpUsed(otpId) {
  await query(`UPDATE otps SET is_used = TRUE WHERE id = $1`, [otpId]);
}

async function incrementOtpAttempts(otpId) {
  await query(`UPDATE otps SET attempts = attempts + 1 WHERE id = $1`, [otpId]);
}

async function countOtpResends(userId, otpType) {
  const { rows } = await query(
    `SELECT COUNT(*) AS cnt
     FROM otps
     WHERE user_id = $1 AND otp_type = $2 AND created_at > NOW() - INTERVAL '30 minutes'`,
    [userId, otpType],
  );
  return parseInt(rows[0].cnt);
}

// ─── Refresh Tokens ───────────────────────────────────────────────────────────

async function storeRefreshToken({ userId, tokenHash, deviceInfo, ipAddress, expiresAt }) {
  await query(
    `INSERT INTO refresh_tokens (user_id, token_hash, device_info, ip_address, expires_at)
     VALUES ($1, $2, $3, $4, $5)`,
    [userId, tokenHash, deviceInfo, ipAddress, expiresAt],
  );
}

async function findRefreshToken(tokenHash) {
  const { rows } = await query(
    `SELECT id, user_id, expires_at, is_revoked
     FROM refresh_tokens
     WHERE token_hash = $1`,
    [tokenHash],
  );
  return rows[0] || null;
}

async function revokeRefreshToken(tokenHash) {
  await query(
    `UPDATE refresh_tokens SET is_revoked = TRUE WHERE token_hash = $1`,
    [tokenHash],
  );
}

async function revokeAllUserTokens(userId) {
  await query(
    `UPDATE refresh_tokens SET is_revoked = TRUE WHERE user_id = $1`,
    [userId],
  );
}

// ─── Password Reset ───────────────────────────────────────────────────────────

async function createPasswordReset({ userId, tokenHash, expiresAt }) {
  // Invalidate previous resets
  await query(
    `UPDATE password_resets SET is_used = TRUE WHERE user_id = $1 AND is_used = FALSE`,
    [userId],
  );
  await query(
    `INSERT INTO password_resets (user_id, token_hash, expires_at) VALUES ($1, $2, $3)`,
    [userId, tokenHash, expiresAt],
  );
}

async function findValidPasswordReset(tokenHash) {
  const { rows } = await query(
    `SELECT id, user_id, expires_at
     FROM password_resets
     WHERE token_hash = $1 AND is_used = FALSE AND expires_at > NOW()`,
    [tokenHash],
  );
  return rows[0] || null;
}

async function markPasswordResetUsed(id) {
  await query(`UPDATE password_resets SET is_used = TRUE WHERE id = $1`, [id]);
}

module.exports = {
  upsertPendingRegistration,
  findPendingByEmail,
  findPendingByPhone,
  findPendingByCnic,
  updatePendingOtp,
  deletePendingByEmail,
  createUser,
  findUserByEmail,
  findUserByPhone,
  findUserByCnic,
  findUserById,
  markUserVerified,
  incrementFailedAttempts,
  lockUser,
  resetFailedAttempts,
  updatePassword,
  deactivateUser,
  createOtp,
  findValidOtp,
  markOtpUsed,
  incrementOtpAttempts,
  countOtpResends,
  storeRefreshToken,
  findRefreshToken,
  revokeRefreshToken,
  revokeAllUserTokens,
  createPasswordReset,
  findValidPasswordReset,
  markPasswordResetUsed,
};