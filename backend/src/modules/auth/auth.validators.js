const { body } = require('express-validator');

const VALID_ROLES  = ['landowner', 'manager', 'worker'];
const CNIC_REGEX   = /^\d{5}-\d{7}-\d{1}$/;

const registerValidator = [
  body('fullName').trim().notEmpty().withMessage('Full name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Full name must be 2–100 characters'),

  body('email').trim().notEmpty().withMessage('Email is required')
    .isEmail().withMessage('Invalid email format').normalizeEmail(),

  body('phone').trim().notEmpty().withMessage('Phone number is required')
    .matches(/^\+92\s?3\d{9}$|^03\d{9}$/).withMessage('Invalid Pakistani phone number'),

  body('cnic').trim().notEmpty().withMessage('CNIC is required')
    .matches(CNIC_REGEX).withMessage('CNIC must be in format XXXXX-XXXXXXX-X'),

  body('password').notEmpty().withMessage('Password is required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter')
    .matches(/[0-9]/).withMessage('Password must contain at least one number'),

  body('role').notEmpty().withMessage('Role is required')
    .isIn(VALID_ROLES).withMessage(`Role must be one of: ${VALID_ROLES.join(', ')}`),
];

// Flutter sends { email, otp, otpType? }
const verifyOtpValidator = [
  body('email').trim().notEmpty().withMessage('Email is required')
    .isEmail().withMessage('Invalid email format').normalizeEmail(),

  body('otp').notEmpty().withMessage('OTP is required')
    .isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits')
    .isNumeric().withMessage('OTP must be numeric'),

  body('otpType').optional()
    .isIn(['email_verification', 'phone_verification']).withMessage('Invalid OTP type'),
];

// Flutter sends { email, otpType? }
const resendOtpValidator = [
  body('email').trim().notEmpty().withMessage('Email is required')
    .isEmail().withMessage('Invalid email format').normalizeEmail(),

  body('otpType').optional()
    .isIn(['email_verification', 'phone_verification']).withMessage('Invalid OTP type'),
];

// Flutter sends { email, password } — also accept { identifier, password }
const loginValidator = [
  body('identifier').optional().trim(),
  body('email').optional().trim(),

  body('identifier').custom((value, { req }) => {
    if (!value && !req.body.email) {
      throw new Error('Email or phone number is required');
    }
    return true;
  }),

  body('password').notEmpty().withMessage('Password is required'),
];

const refreshValidator = [
  body('refreshToken').notEmpty().withMessage('Refresh token is required'),
];

const forgotPasswordValidator = [
  body('email').trim().notEmpty().isEmail().normalizeEmail()
    .withMessage('Valid email is required'),
];

const resetPasswordValidator = [
  body('token').notEmpty().withMessage('Reset token is required'),
  body('newPassword').notEmpty().withMessage('New password is required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter')
    .matches(/[0-9]/).withMessage('Password must contain at least one number'),
];

const resetPasswordOtpValidator = [
  body('email').trim().notEmpty().isEmail().normalizeEmail()
    .withMessage('Valid email is required'),
  body('otp').notEmpty().withMessage('OTP is required')
    .isLength({ min: 6, max: 6 }).isNumeric().withMessage('OTP must be 6 digits'),
  body('newPassword').notEmpty().withMessage('New password is required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/[A-Z]/).withMessage('Must contain at least one uppercase letter')
    .matches(/[0-9]/).withMessage('Must contain at least one number'),
];

module.exports = {
  registerValidator,
  verifyOtpValidator,
  resendOtpValidator,
  loginValidator,
  refreshValidator,
  forgotPasswordValidator,
  resetPasswordValidator,
  resetPasswordOtpValidator,
};