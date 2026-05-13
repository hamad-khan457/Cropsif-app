const crypto = require('crypto');
const repo = require('./auth.repository');
const { hashPassword, comparePassword } = require('../../utils/hash.utils');
const { generateOtp, otpExpiresAt } = require('../../utils/otp.utils');
const { buildTokenPair, hashToken, verifyRefreshToken } = require('../../utils/jwt.utils');
const { sendOtpEmail, sendPasswordResetEmail, sendPasswordResetOtpEmail } = require('../../utils/email.utils');

const MAX_FAILED          = parseInt(process.env.MAX_FAILED_LOGIN_ATTEMPTS  || '5');
const LOCK_MINUTES        = parseInt(process.env.ACCOUNT_LOCK_DURATION_MINUTES || '15');
const RESET_EXPIRES_MINUTES = parseInt(process.env.PASSWORD_RESET_EXPIRES_MINUTES || '15');
const MAX_OTP_RESENDS     = parseInt(process.env.OTP_MAX_RESEND_ATTEMPTS    || '3');

// ─── Registration ─────────────────────────────────────────────────────────────
// No row is written to the users table here. Data goes to pending_registrations
// only. The user row is created in verifyOtpByEmail once the OTP is confirmed.

async function register({ fullName, email, phone, cnic, password, role }) {
  // Check verified users
  const byEmail = await repo.findUserByEmail(email);
  if (byEmail) throw Object.assign(new Error('Account already exists with this email'), { statusCode: 409 });

  // Check phone/CNIC against verified users AND any OTHER pending entry
  const byPhone = await repo.findUserByPhone(phone);
  if (byPhone) throw Object.assign(new Error('Account already exists with this phone number'), { statusCode: 409 });
  const pendingPhone = await repo.findPendingByPhone(phone);
  if (pendingPhone) {
    // Only block if it's a DIFFERENT email (same person retrying is fine)
    const existing = await repo.findPendingByEmail(email);
    if (!existing || existing.phone !== phone) {
      throw Object.assign(new Error('Account already exists with this phone number'), { statusCode: 409 });
    }
  }

  const byCnic = await repo.findUserByCnic(cnic);
  if (byCnic) throw Object.assign(new Error('Account already exists with this CNIC'), { statusCode: 409 });
  const pendingCnic = await repo.findPendingByCnic(cnic);
  if (pendingCnic) {
    const existing = await repo.findPendingByEmail(email);
    if (!existing || existing.cnic !== cnic) {
      throw Object.assign(new Error('Account already exists with this CNIC'), { statusCode: 409 });
    }
  }

  const passwordHash = await hashPassword(password);
  const otpCode  = generateOtp();
  const expiresAt = otpExpiresAt();

  // Save to pending_registrations (upsert so same email can retry)
  await repo.upsertPendingRegistration({
    fullName, email, phone, cnic, passwordHash, role,
    otpCode, otpExpiresAt: expiresAt,
  });

  await sendOtpEmail(email, fullName, otpCode);

  return { message: 'Registration initiated. Please verify your email with the OTP sent.' };
}

// ─── OTP Verification ─────────────────────────────────────────────────────────

// Used for password-reset and any non-registration OTP type (user already exists)
async function verifyOtp(userId, otpCode, otpType = 'email_verification') {
  const record = await repo.findValidOtp(userId, otpType);
  if (!record) throw Object.assign(new Error('OTP expired or not found'), { statusCode: 400 });

  if (record.otp_code !== otpCode) {
    await repo.incrementOtpAttempts(record.id);
    throw Object.assign(new Error('Invalid OTP'), { statusCode: 400 });
  }
  await repo.markOtpUsed(record.id);
  return { verified: true };
}

// Email-based entry point (used by the controller for ALL OTP types)
async function verifyOtpByEmail(email, otpCode, otpType = 'email_verification') {
  if (otpType === 'email_verification') {
    // Registration path — user does NOT exist in users table yet
    const pending = await repo.findPendingByEmail(email);
    if (!pending) throw Object.assign(new Error('No pending registration found for this email'), { statusCode: 404 });

    if (new Date(pending.otp_expires_at) < new Date()) {
      throw Object.assign(new Error('OTP has expired. Please request a new one.'), { statusCode: 400 });
    }
    if (pending.otp_code !== otpCode) {
      throw Object.assign(new Error('Invalid OTP'), { statusCode: 400 });
    }

    // OTP is valid — NOW create the user in the users table
    const user = await repo.createUser({
      fullName:     pending.full_name,
      email:        pending.email,
      phone:        pending.phone,
      cnic:         pending.cnic,
      passwordHash: pending.password_hash,
      role:         pending.role,
    });
    await repo.markUserVerified(user.id);

    // Clean up pending entry
    await repo.deletePendingByEmail(email);

    // Auto-login — return tokens so the app skips the login step
    const tokens    = buildTokenPair({ ...user, is_verified: true });
    const tokenHash = hashToken(tokens.refreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await repo.storeRefreshToken({ userId: user.id, tokenHash, deviceInfo: null, ipAddress: null, expiresAt });

    return {
      verified:     true,
      accessToken:  tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: {
        id:          user.id,
        full_name:   user.full_name,
        email:       user.email,
        role:        user.role,
        is_verified: true,
        is_active:   user.is_active,
        created_at:  user.created_at,
      },
    };
  }

  // Non-registration OTP (password reset etc.) — user must already exist
  const user = await repo.findUserByEmail(email);
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  return verifyOtp(user.id, otpCode, otpType);
}

// ─── OTP Resend ───────────────────────────────────────────────────────────────

// Used for password-reset resend (user already exists in users table)
async function resendOtp(userId, otpType = 'email_verification') {
  const resendCount = await repo.countOtpResends(userId, otpType);
  if (resendCount >= MAX_OTP_RESENDS) {
    throw Object.assign(
      new Error('Maximum OTP resend attempts exceeded. Please wait 30 minutes.'),
      { statusCode: 429 },
    );
  }
  const user = await repo.findUserById(userId);
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  await _issueAndSendOtp(user, otpType);
  return { message: 'OTP resent successfully' };
}

// Email-based resend — handles both pending registrations and verified users
async function resendOtpByEmail(email, otpType = 'email_verification') {
  if (otpType === 'email_verification') {
    // Look in pending_registrations (user not yet created)
    const pending = await repo.findPendingByEmail(email);
    if (!pending) {
      // Check if a verified account exists for this email
      const user = await repo.findUserByEmail(email);
      if (user) {
        throw Object.assign(
          new Error('This email is already registered. Please log in.'),
          { statusCode: 409 },
        );
      }
      throw Object.assign(new Error('User not found'), { statusCode: 404 });
    }

    if (pending.resend_count >= MAX_OTP_RESENDS) {
      throw Object.assign(
        new Error('Maximum OTP resend attempts exceeded. Please wait 30 minutes.'),
        { statusCode: 429 },
      );
    }

    const otpCode  = generateOtp();
    const expiresAt = otpExpiresAt();
    await repo.updatePendingOtp(email, otpCode, expiresAt);
    await sendOtpEmail(email, pending.full_name, otpCode);
    return { message: 'OTP resent successfully' };
  }

  // Password-reset and other types — look in users table
  const user = await repo.findUserByEmail(email);
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  return resendOtp(user.id, otpType);
}

// ─── Login ────────────────────────────────────────────────────────────────────

async function login({ identifier, password, deviceInfo, ipAddress }) {
  // Accept email or phone
  const isEmail = identifier.includes('@');
  const user = isEmail
    ? await repo.findUserByEmail(identifier)
    : await repo.findUserByPhone(identifier);

  if (!user) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });
  if (!user.is_active) throw Object.assign(new Error('Account is deactivated'), { statusCode: 403 });
  if (!user.is_verified) throw Object.assign(new Error('Account not verified. Please verify your OTP.'), { statusCode: 403 });

  if (user.is_locked) {
    const now = new Date();
    if (user.locked_until > now) {
      const mins = Math.ceil((user.locked_until - now) / 60000);
      throw Object.assign(
        new Error(`Account locked. Try again in ${mins} minute(s).`),
        { statusCode: 423 },
      );
    }
    await repo.resetFailedAttempts(user.id);
  }

  const valid = await comparePassword(password, user.password_hash);
  if (!valid) {
    await repo.incrementFailedAttempts(user.id);
    const { rows } = await require('../../config/database').query(
      'SELECT failed_attempts FROM users WHERE id = $1',
      [user.id],
    );
    const attempts = rows[0].failed_attempts;

    if (attempts >= MAX_FAILED) {
      const lockUntil = new Date(Date.now() + LOCK_MINUTES * 60 * 1000);
      await repo.lockUser(user.id, lockUntil);
      throw Object.assign(
        new Error(`Too many failed attempts. Account locked for ${LOCK_MINUTES} minutes.`),
        { statusCode: 423 },
      );
    }

    throw Object.assign(
      new Error(`Invalid credentials. ${MAX_FAILED - attempts} attempt(s) remaining.`),
      { statusCode: 401 },
    );
  }

  await repo.resetFailedAttempts(user.id);

  const tokens    = buildTokenPair(user);
  const tokenHash = hashToken(tokens.refreshToken);
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  await repo.storeRefreshToken({ userId: user.id, tokenHash, deviceInfo, ipAddress, expiresAt });

  return {
    user: {
      id:          user.id,
      full_name:   user.full_name,
      email:       user.email,
      role:        user.role,
      is_verified: user.is_verified,
      is_active:   user.is_active,
      created_at:  user.created_at,
    },
    accessToken:  tokens.accessToken,
    refreshToken: tokens.refreshToken,
  };
}

// ─── Token Refresh ────────────────────────────────────────────────────────────

async function refreshTokens(rawRefreshToken) {
  let decoded;
  try {
    decoded = verifyRefreshToken(rawRefreshToken);
  } catch {
    throw Object.assign(new Error('Invalid or expired refresh token'), { statusCode: 401 });
  }

  const tokenHash = hashToken(rawRefreshToken);
  const stored    = await repo.findRefreshToken(tokenHash);

  if (!stored || stored.is_revoked || new Date(stored.expires_at) < new Date()) {
    throw Object.assign(new Error('Refresh token revoked or expired'), { statusCode: 401 });
  }

  const user = await repo.findUserById(decoded.sub);
  if (!user || !user.is_active) {
    throw Object.assign(new Error('User not found or inactive'), { statusCode: 401 });
  }

  await repo.revokeRefreshToken(tokenHash);
  const tokens    = buildTokenPair(user);
  const newHash   = hashToken(tokens.refreshToken);
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  await repo.storeRefreshToken({ userId: user.id, tokenHash: newHash, expiresAt });

  return tokens;
}

// ─── Logout ───────────────────────────────────────────────────────────────────

async function logout(rawRefreshToken, logoutAllDevices = false, userId = null) {
  if (logoutAllDevices && userId) {
    await repo.revokeAllUserTokens(userId);
  } else if (rawRefreshToken) {
    await repo.revokeRefreshToken(hashToken(rawRefreshToken));
  }
  return { message: 'Logged out successfully' };
}

// ─── Forgot Password ──────────────────────────────────────────────────────────

async function forgotPassword(email) {
  const user = await repo.findUserByEmail(email);
  // Always return the same message to prevent email enumeration
  if (!user || !user.is_active) return { message: 'If that email exists, a reset link was sent.' };

  const rawToken  = crypto.randomBytes(32).toString('hex');
  const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
  const expiresAt = new Date(Date.now() + RESET_EXPIRES_MINUTES * 60 * 1000);

  await repo.createPasswordReset({ userId: user.id, tokenHash, expiresAt });

  const resetLink = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${rawToken}`;

  // Fire-and-forget — email failure must not block the API response
  sendPasswordResetEmail(user.email, resetLink).catch((err) => {
    console.error('[forgotPassword] email send failed:', err.message);
  });

  return { message: 'If that email exists, a reset link was sent.' };
}

// ─── OTP-based Password Reset ─────────────────────────────────────────────────

async function forgotPasswordOtp(email) {
  const user = await repo.findUserByEmail(email);
  // Always return generic message to prevent email enumeration
  if (!user || !user.is_active) {
    return { message: 'If that email is registered, you will receive a reset code.' };
  }

  const code      = generateOtp();
  const expiresAt = otpExpiresAt();
  await repo.createOtp({ userId: user.id, otpCode: code, otpType: 'password_reset', expiresAt });

  sendPasswordResetOtpEmail(user.email, code).catch((err) => {
    console.error('[forgotPasswordOtp] email failed:', err.message);
  });

  return { message: 'A 6-digit reset code has been sent to your email.' };
}

async function resetPasswordWithOtp(email, otp, newPassword) {
  const user = await repo.findUserByEmail(email);
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });

  const record = await repo.findValidOtp(user.id, 'password_reset');
  if (!record) throw Object.assign(new Error('Reset code expired or not found'), { statusCode: 400 });

  if (record.otp_code !== otp) {
    await repo.incrementOtpAttempts(record.id);
    throw Object.assign(new Error('Invalid reset code'), { statusCode: 400 });
  }

  await repo.markOtpUsed(record.id);
  const passwordHash = await hashPassword(newPassword);
  await repo.updatePassword(user.id, passwordHash);
  await repo.revokeAllUserTokens(user.id);

  return { message: 'Password reset successfully. Please log in.' };
}

// ─── Reset Password ───────────────────────────────────────────────────────────

async function resetPassword(rawToken, newPassword) {
  const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
  const record    = await repo.findValidPasswordReset(tokenHash);

  if (!record) throw Object.assign(new Error('Reset link is invalid or expired'), { statusCode: 400 });

  const passwordHash = await hashPassword(newPassword);
  await repo.updatePassword(record.user_id, passwordHash);
  await repo.markPasswordResetUsed(record.id);
  await repo.revokeAllUserTokens(record.user_id);

  return { message: 'Password reset successfully. Please log in.' };
}

// ─── Private helpers ──────────────────────────────────────────────────────────

async function _issueAndSendOtp(user, otpType) {
  const code      = generateOtp();
  const expiresAt = otpExpiresAt();
  await repo.createOtp({ userId: user.id, otpCode: code, otpType, expiresAt });

  // Await email so the API only responds after the email is confirmed sent.
  // If it fails, log and continue — OTP is in the DB and user can resend.
  try {
    await sendOtpEmail(user.email, code);
  } catch (err) {
    console.error('[_issueAndSendOtp] email send failed:', err.message);
  }
}

module.exports = {
  register,
  verifyOtp,
  verifyOtpByEmail,
  resendOtp,
  resendOtpByEmail,
  login,
  refreshTokens,
  logout,
  forgotPassword,
  resetPassword,
  forgotPasswordOtp,
  resetPasswordWithOtp,
};