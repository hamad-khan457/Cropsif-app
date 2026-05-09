const { error } = require('../utils/response.utils');

function notFoundHandler(req, res) {
  return error(res, `Route ${req.method} ${req.path} not found`, 404);
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  console.error('[Error]', err.message, err.stack);

  // Postgres unique violation
  if (err.code === '23505') {
    return error(res, 'A record with that value already exists', 409);
  }

  // Postgres foreign key violation
  if (err.code === '23503') {
    return error(res, 'Referenced record does not exist', 400);
  }

  const statusCode = err.statusCode || 500;
  const message = statusCode < 500 ? err.message : 'Internal server error';
  return error(res, message, statusCode);
}

module.exports = { notFoundHandler, errorHandler };