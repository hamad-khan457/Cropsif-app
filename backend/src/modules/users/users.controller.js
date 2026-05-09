const usersService = require('./users.service');
const { success } = require('../../utils/response.utils');

async function getProfile(req, res, next) {
  try {
    const profile = await usersService.getProfile(req.user.sub);
    return success(res, { profile });
  } catch (err) {
    next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const updated = await usersService.updateProfile(req.user.sub, req.body);
    return success(res, { user: updated }, 'Profile updated');
  } catch (err) {
    next(err);
  }
}

async function changePassword(req, res, next) {
  try {
    const { currentPassword, newPassword } = req.body;
    const result = await usersService.changePassword(req.user.sub, currentPassword, newPassword);
    return success(res, {}, result.message);
  } catch (err) {
    next(err);
  }
}

async function getNotificationPrefs(req, res, next) {
  try {
    const prefs = await usersService.getNotificationPrefs(req.user.sub);
    return success(res, { preferences: prefs });
  } catch (err) {
    next(err);
  }
}

async function updateNotificationPrefs(req, res, next) {
  try {
    const prefs = await usersService.updateNotificationPrefs(req.user.sub, req.body);
    return success(res, { preferences: prefs }, 'Notification preferences updated');
  } catch (err) {
    next(err);
  }
}

async function deactivateAccount(req, res, next) {
  try {
    const { password } = req.body;
    const result = await usersService.deactivateAccount(req.user.sub, password);
    return success(res, {}, result.message);
  } catch (err) {
    next(err);
  }
}

async function exportData(req, res, next) {
  try {
    const data = await usersService.exportData(req.user.sub);
    return success(res, { export: data }, 'Data exported');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getProfile,
  updateProfile,
  changePassword,
  getNotificationPrefs,
  updateNotificationPrefs,
  deactivateAccount,
  exportData,
};