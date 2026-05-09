const repo = require('./users.repository');
const authRepo = require('../auth/auth.repository');
const { hashPassword, comparePassword } = require('../../utils/hash.utils');

async function getProfile(userId) {
  const profile = await repo.getProfile(userId);
  if (!profile) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  return profile;
}

async function updateProfile(userId, updates) {
  const updated = await repo.updateProfile(userId, updates);
  if (!updated) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  return updated;
}

async function changePassword(userId, currentPassword, newPassword) {
  const { rows } = await require('../../config/database').query(
    'SELECT password_hash FROM users WHERE id = $1',
    [userId],
  );
  if (!rows[0]) throw Object.assign(new Error('User not found'), { statusCode: 404 });

  const valid = await comparePassword(currentPassword, rows[0].password_hash);
  if (!valid) throw Object.assign(new Error('Current password is incorrect'), { statusCode: 400 });

  const newHash = await hashPassword(newPassword);
  await authRepo.updatePassword(userId, newHash);

  return { message: 'Password changed successfully' };
}

async function updateNotificationPrefs(userId, prefs) {
  return repo.upsertNotificationPrefs(userId, prefs);
}

async function getNotificationPrefs(userId) {
  return repo.getNotificationPrefs(userId);
}

async function deactivateAccount(userId, password) {
  const { rows } = await require('../../config/database').query(
    'SELECT password_hash FROM users WHERE id = $1',
    [userId],
  );
  if (!rows[0]) throw Object.assign(new Error('User not found'), { statusCode: 404 });

  const valid = await comparePassword(password, rows[0].password_hash);
  if (!valid) throw Object.assign(new Error('Password confirmation failed'), { statusCode: 400 });

  await repo.deactivateUser(userId);
  await authRepo.revokeAllUserTokens(userId);

  return { message: 'Account deactivated successfully' };
}

async function exportData(userId) {
  const data = await repo.exportUserData(userId);
  if (!data) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  return data;
}

module.exports = {
  getProfile,
  updateProfile,
  changePassword,
  updateNotificationPrefs,
  getNotificationPrefs,
  deactivateAccount,
  exportData,
};