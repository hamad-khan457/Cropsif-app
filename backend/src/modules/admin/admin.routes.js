const { Router } = require('express');
const controller = require('./admin.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const { authorize }    = require('../../middleware/role.middleware');
const { body }         = require('express-validator');
const { validate }     = require('../../middleware/validate.middleware');

const router = Router();

router.use(authenticate, authorize('admin'));

router.get('/stats',          controller.getStats);
router.get('/users',          controller.listUsers);
router.get('/users/:id',      controller.getUserById);
router.patch(
  '/users/:id/status',
  [body('isActive').isBoolean().withMessage('isActive must be boolean')],
  validate,
  controller.setUserStatus,
);

module.exports = router;