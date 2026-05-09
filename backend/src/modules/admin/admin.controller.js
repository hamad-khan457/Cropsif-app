const adminService = require('./admin.service');
const { success } = require('../../utils/response.utils');

async function getStats(req, res, next) {
  try {
    const stats = await adminService.getStats();
    return success(res, { stats });
  } catch (err) { next(err); }
}

async function listUsers(req, res, next) {
  try {
    const { search, role, status, page, limit } = req.query;
    const result = await adminService.listUsers({ search, role, status, page, limit });
    return success(res, result);
  } catch (err) { next(err); }
}

async function getUserById(req, res, next) {
  try {
    const user = await adminService.getUserById(req.params.id);
    return success(res, { user });
  } catch (err) { next(err); }
}

async function setUserStatus(req, res, next) {
  try {
    const { isActive } = req.body;
    const user = await adminService.setUserStatus(req.user.sub, req.params.id, isActive);
    return success(res, { user }, `User ${isActive ? 'activated' : 'deactivated'} successfully`);
  } catch (err) { next(err); }
}

module.exports = { getStats, listUsers, getUserById, setUserStatus };