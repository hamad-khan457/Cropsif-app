const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');

const authRoutes    = require('./modules/auth/auth.routes');
const usersRoutes   = require('./modules/users/users.routes');
const adminRoutes   = require('./modules/admin/admin.routes');
const parcelRoutes  = require('./modules/parcels/parcel.routes');
const scanRoutes    = require('./modules/scan/scan.routes');
const { errorHandler, notFoundHandler } = require('./middleware/error.middleware');

const app = express();

// Trust Docker/nginx reverse proxy so rate-limiter sees real client IP
app.set('trust proxy', 1);

// Security & parsing
app.use(helmet());
app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:5173',
    /^http:\/\/192\.168\.\d+\.\d+:\d+$/,   // Home networks (192.168.x.x)
    /^http:\/\/10\.\d+\.\d+\.\d+:\d+$/,    // University / corporate (10.x.x.x)
    /^http:\/\/172\.(1[6-9]|2\d|3[01])\.\d+\.\d+:\d+$/,  // Docker / VPN
  ],
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok', service: 'cropsify-api' }));

// Module 1 routes
app.use('/api/v1/auth',    authRoutes);
app.use('/api/v1/users',   usersRoutes);
app.use('/api/v1/admin',   adminRoutes);

// Module 2 routes
app.use('/api/v1/parcels', parcelRoutes);

// ML scan
app.use('/api/v1/scan', scanRoutes);

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;