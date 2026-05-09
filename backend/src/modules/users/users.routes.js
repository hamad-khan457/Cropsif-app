const { Router } = require('express');
const controller = require('./users.controller');
const {
  updateProfileValidator,
  changePasswordValidator,
  notificationPrefsValidator,
  deactivateValidator,
} = require('./users.validators');
const { validate } = require('../../middleware/validate.middleware');
const { authenticate } = require('../../middleware/auth.middleware');

const router = Router();

// All user routes require authentication
router.use(authenticate);

router.get('/me',                                                     controller.getProfile);
router.patch('/me',               updateProfileValidator,    validate, controller.updateProfile);
router.put('/me/password',        changePasswordValidator,   validate, controller.changePassword);
router.get('/me/notifications',                                       controller.getNotificationPrefs);
router.put('/me/notifications',   notificationPrefsValidator,validate, controller.updateNotificationPrefs);
router.delete('/me',              deactivateValidator,       validate, controller.deactivateAccount);
router.get('/me/export',                                              controller.exportData);

module.exports = router;