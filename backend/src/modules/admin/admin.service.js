const repo = require('./admin.repository');
const authRepo = require('../auth/auth.repository');

async function listUsers({ search, role, status, page = 1, limit = 20 }) {
  const safePage  = Math.max(1, parseInt(page, 10) || 1);
  const safeLimit = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const offset    = (safePage - 1) * safeLimit;
  const { users, total } = await repo.listUsers({ search, role, status, limit: safeLimit, offset });
  return {
    users,
    pagination: {
      total,
      page:  safePage,
      limit: safeLimit,
      pages: Math.ceil(total / safeLimit),
    },
  };
}

async function getUserById(id) {
  const user = await repo.getUserById(id);
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  return user;
}

async function setUserStatus(adminId, targetId, isActive) {
  if (adminId === targetId) {
    throw Object.assign(new Error('Cannot change your own status'), { statusCode: 400 });
  }
  const user = await repo.setUserStatus(targetId, isActive);
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });

  // Revoke all sessions when deactivating
  if (!isActive) await authRepo.revokeAllUserTokens(targetId);
  return user;
}

async function getStats() {
  return repo.getStats();
}

module.exports = { listUsers, getUserById, setUserStatus, getStats };