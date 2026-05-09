const { Router } = require('express');
const controller = require('./auth.controller');
const {
  registerValidator,
  verifyOtpValidator,
  resendOtpValidator,
  loginValidator,
  refreshValidator,
  forgotPasswordValidator,
  resetPasswordValidator,
  resetPasswordOtpValidator,
} = require('./auth.validators');
const { validate } = require('../../middleware/validate.middleware');
const { authenticate } = require('../../middleware/auth.middleware');
const { authLimiter } = require('../../middleware/rateLimiter.middleware');

const router = Router();

// Public — apply strict rate limiter
router.post('/register',         authLimiter, registerValidator,         validate, controller.register);
router.post('/verify-otp',       authLimiter, verifyOtpValidator,        validate, controller.verifyOtp);
router.post('/resend-otp',       authLimiter, resendOtpValidator,        validate, controller.resendOtp);
router.post('/login',            authLimiter, loginValidator,            validate, controller.login);
router.post('/refresh',                       refreshValidator,          validate, controller.refreshTokens);
router.post('/forgot-password',     authLimiter, forgotPasswordValidator,   validate, controller.forgotPassword);
router.post('/reset-password',                resetPasswordValidator,    validate, controller.resetPassword);
// OTP-based password reset (used by mobile app)
router.post('/forgot-password-otp', authLimiter, forgotPasswordValidator,   validate, controller.forgotPasswordOtp);
router.post('/reset-password-otp',             resetPasswordOtpValidator, validate, controller.resetPasswordWithOtp);

// Protected
router.post('/logout', authenticate, controller.logout);

module.exports = router;