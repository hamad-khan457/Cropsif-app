const { body } = require('express-validator');

const updateProfileValidator = [
  body('fullName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 }).withMessage('Full name must be 2–100 characters'),
  body('phone')
    .optional()
    .trim()
    .matches(/^\+92\s?3\d{9}$|^03\d{9}$/).withMessage('Invalid Pakistani phone number'),
];

const changePasswordValidator = [
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword')
    .notEmpty().withMessage('New password is required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter')
    .matches(/[0-9]/).withMessage('Password must contain at least one number'),
];

const notificationPrefsValidator = [
  body('pushAlerts').optional().isBoolean().withMessage('pushAlerts must be boolean'),
  body('emailDigest').optional().isBoolean().withMessage('emailDigest must be boolean'),
  body('smsAlerts').optional().isBoolean().withMessage('smsAlerts must be boolean'),
  body('quietHoursStart')
    .optional({ nullable: true })
    .matches(/^\d{2}:\d{2}$/).withMessage('quietHoursStart must be HH:MM'),
  body('quietHoursEnd')
    .optional({ nullable: true })
    .matches(/^\d{2}:\d{2}$/).withMessage('quietHoursEnd must be HH:MM'),
];

const deactivateValidator = [
  body('password').notEmpty().withMessage('Password confirmation is required'),
];

module.exports = {
  updateProfileValidator,
  changePasswordValidator,
  notificationPrefsValidator,
  deactivateValidator,
};