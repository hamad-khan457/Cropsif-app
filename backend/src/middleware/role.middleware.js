const { error } = require('../utils/response.utils');

/**
 * Restrict access to one or more roles.
 * Must be used after authenticate middleware.
 * @param {...string} roles - Allowed roles
 */
function authorize(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return error(res, 'Unauthenticated', 401);
    }
    if (!roles.includes(req.user.role)) {
      return error(res, 'Access denied: insufficient permissions', 403);
    }
    next();
  };
}

module.exports = { authorize };