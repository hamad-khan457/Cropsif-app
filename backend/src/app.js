const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');

const authRoutes    = require('./modules/auth/auth.routes');
const usersRoutes   = require('./modules/users/users.routes');
const adminRoutes   = require('./modules/admin/admin.routes');
const parcelRoutes  = require('./modules/parcels/parcel.routes');
const { errorHandler, notFoundHandler } = require('./middleware/error.middleware');

const app = express();

// Trust Docker/nginx reverse proxy so rate-limiter sees real client IP
app.set('trust proxy', 1);

// Security & parsing
app.use(helmet());
app.use(cors({
  origin: [
    'http://localhost:3000',   // React dev server & Docker web container
    'http://localhost:5173',   // Vite default port
    /^http:\/\/192\.168\.\d+\.\d+:\d+$/,  // LAN access from physical devices
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

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;