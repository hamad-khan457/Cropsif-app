const authService = require('./auth.service');
const { success } = require('../../utils/response.utils');

async function register(req, res, next) {
  try {
    const { fullName, email, phone, cnic, password, role } = req.body;
    const result = await authService.register({ fullName, email, phone, cnic, password, role });
    return success(res, result, 'Registration successful', 201);
  } catch (err) {
    next(err);
  }
}

// Flutter sends { email, otp, otpType? }
async function verifyOtp(req, res, next) {
  try {
    const { email, otp, otpType } = req.body;
    const result = await authService.verifyOtpByEmail(email, otp, otpType || 'registration');
    return success(res, result, 'OTP verified successfully');
  } catch (err) {
    next(err);
  }
}

// Flutter sends { email, otpType? }
async function resendOtp(req, res, next) {
  try {
    const { email, otpType } = req.body;
    const result = await authService.resendOtpByEmail(email, otpType || 'registration');
    return success(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

// Flutter sends { email, password } — also handles { identifier, password }
async function login(req, res, next) {
  try {
    const identifier = req.body.identifier || req.body.email;
    const { password } = req.body;
    const deviceInfo = req.headers['user-agent'] || 'unknown';
    const ipAddress  = req.ip;
    const result = await authService.login({ identifier, password, deviceInfo, ipAddress });
    return success(res, result, 'Login successful');
  } catch (err) {
    next(err);
  }
}

async function refreshTokens(req, res, next) {
  try {
    const { refreshToken } = req.body;
    const tokens = await authService.refreshTokens(refreshToken);
    return success(res, tokens, 'Tokens refreshed');
  } catch (err) {
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    const { refreshToken, logoutAll } = req.body;
    const userId = req.user?.sub;
    const result = await authService.logout(refreshToken, logoutAll === true, userId);
    return success(res, {}, result.message);
  } catch (err) {
    next(err);
  }
}

async function forgotPassword(req, res, next) {
  try {
    const { email } = req.body;
    const result = await authService.forgotPassword(email);
    return success(res, {}, result.message);
  } catch (err) {
    next(err);
  }
}

async function resetPassword(req, res, next) {
  try {
    const { token, newPassword } = req.body;
    const result = await authService.resetPassword(token, newPassword);
    return success(res, {}, result.message);
  } catch (err) {
    next(err);
  }
}

async function forgotPasswordOtp(req, res, next) {
  try {
    const { email } = req.body;
    const result = await authService.forgotPasswordOtp(email);
    return success(res, {}, result.message);
  } catch (err) { next(err); }
}

async function resetPasswordWithOtp(req, res, next) {
  try {
    const { email, otp, newPassword } = req.body;
    const result = await authService.resetPasswordWithOtp(email, otp, newPassword);
    return success(res, {}, result.message);
  } catch (err) { next(err); }
}

module.exports = {
  register,
  verifyOtp,
  resendOtp,
  login,
  refreshTokens,
  logout,
  forgotPassword,
  resetPassword,
  forgotPasswordOtp,
  resetPasswordWithOtp,
};