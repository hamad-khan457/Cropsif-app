const { body } = require('express-validator');

const SOIL_TYPES = ['clay','sandy','loamy','clay-loam','sandy-loam','silt','silty-clay'];
const IRRIGATION = ['canal','tubewell','rainwater','drip','sprinkler','other'];
const SEASONS    = ['rabi','kharif','zaid'];

const createParcelValidator = [
  body('name').trim().notEmpty().withMessage('Parcel name is required')
    .isLength({ max: 100 }).withMessage('Name must be under 100 characters'),

  body('location').optional().trim().isLength({ max: 200 }),

  body('areaAcres').optional()
    .isFloat({ min: 0.1, max: 10000 }).withMessage('Area must be between 0.1 and 10,000 acres'),

  body('soilType').optional()
    .isIn(SOIL_TYPES).withMessage(`Soil type must be one of: ${SOIL_TYPES.join(', ')}`),

  body('phLevel').optional()
    .isFloat({ min: 0, max: 14 }).withMessage('pH must be 0–14'),

  body('nitrogen').optional()
    .isFloat({ min: 0 }).withMessage('Nitrogen (N) must be a positive number'),

  body('phosphorus').optional()
    .isFloat({ min: 0 }).withMessage('Phosphorus (P) must be a positive number'),

  body('potassium').optional()
    .isFloat({ min: 0 }).withMessage('Potassium (K) must be a positive number'),

  body('irrigation').optional()
    .isIn(IRRIGATION).withMessage(`Irrigation must be one of: ${IRRIGATION.join(', ')}`),

  body('coordinates').optional()
    .isArray({ min: 0 }).withMessage('Coordinates must be an array')
    .custom((arr) => {
      if (arr.length > 0 && arr.length < 3) throw new Error('Need at least 3 points for a boundary');
      for (const pt of arr) {
        if (typeof pt.lat !== 'number' || typeof pt.lng !== 'number')
          throw new Error('Each coordinate must have numeric lat and lng');
      }
      return true;
    }),
];

const cropHistoryValidator = [
  body('cropName').trim().notEmpty().withMessage('Crop name is required'),
  body('season').optional().isIn(SEASONS).withMessage(`Season must be: ${SEASONS.join(', ')}`),
  body('year').optional().isInt({ min: 2000, max: 2100 }).withMessage('Valid year required'),
  body('yieldMds').optional().isFloat({ min: 0 }).withMessage('Yield must be positive'),
  body('notes').optional().trim().isLength({ max: 500 }),
];

module.exports = { createParcelValidator, cropHistoryValidator };
