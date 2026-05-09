const { Router } = require('express');
const controller = require('./parcel.controller');
const { createParcelValidator, cropHistoryValidator } = require('./parcel.validators');
const { validate } = require('../../middleware/validate.middleware');
const { authenticate } = require('../../middleware/auth.middleware');

const router = Router();

// All parcel routes require authentication
router.use(authenticate);

router.get('/',           controller.list);
router.post('/',          createParcelValidator, validate, controller.create);
router.get('/:id',        controller.getOne);
router.patch('/:id',      createParcelValidator, validate, controller.update);
router.delete('/:id',     controller.remove);
router.post('/:id/history', cropHistoryValidator, validate, controller.addHistory);

module.exports = router;
