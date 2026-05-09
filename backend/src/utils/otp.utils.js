const crypto = require('crypto');

/**
 * Generate a cryptographically secure 6-digit OTP.
 */
function generateOtp() {
  const buffer = crypto.randomBytes(3);
  const num = buffer.readUIntBE(0, 3) % 1000000;
  return String(num).padStart(6, '0');
}

/**
 * Calculate OTP expiry timestamp.
 * @param {number} minutes - Default 3 minutes per SRS FR1.12
 */
function otpExpiresAt(minutes = parseInt(process.env.OTP_EXPIRES_MINUTES || '3')) {
  return new Date(Date.now() + minutes * 60 * 1000);
}

module.exports = { generateOtp, otpExpiresAt };