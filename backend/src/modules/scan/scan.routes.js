const express  = require('express');
const multer   = require('multer');
const { predict } = require('./scan.controller');
const { authenticate } = require('../../middleware/auth.middleware');

const upload = multer({
  storage: multer.memoryStorage(),
  limits:  { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Only image files are allowed'));
  },
});

const router = express.Router();

// POST /api/v1/scan/predict
router.post('/predict', authenticate, (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (!err) return next();
    // Return a proper 400 for multer validation errors instead of crashing to 500
    const msg = err.code === 'LIMIT_FILE_SIZE'
      ? 'Image too large. Maximum size is 10 MB.'
      : (err.message || 'Invalid file upload.');
    return res.status(400).json({ message: msg });
  });
}, predict);

module.exports = router;
