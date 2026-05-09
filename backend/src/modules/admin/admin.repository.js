const { query } = require('../../config/database');

async function listUsers({ search = '', role = '', status = '', limit = 20, offset = 0 }) {
  const conditions = ['1=1'];
  const params = [];

  if (search) {
    params.push(`%${search}%`);
    conditions.push(`(u.full_name ILIKE $${params.length} OR u.email ILIKE $${params.length} OR u.cnic ILIKE $${params.length})`);
  }
  if (role) {
    params.push(role);
    conditions.push(`u.role = $${params.length}`);
  }
  if (status === 'active')   conditions.push('u.is_active = TRUE');
  if (status === 'inactive') conditions.push('u.is_active = FALSE');
  if (status === 'unverified') conditions.push('u.is_verified = FALSE');

  const where = conditions.join(' AND ');

  const countRes = await query(`SELECT COUNT(*) FROM users u WHERE ${where}`, params);
  const total = parseInt(countRes.rows[0].count, 10);

  params.push(limit, offset);
  const { rows } = await query(
    `SELECT u.id, u.full_name, u.email, u.phone, u.cnic, u.role,
            u.is_verified, u.is_active, u.failed_attempts, u.locked_until, u.created_at
     FROM users u
     WHERE ${where}
     ORDER BY u.created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params,
  );
  return { users: rows, total };
}

async function getUserById(id) {
  const { rows } = await query(
    `SELECT u.id, u.full_name, u.email, u.phone, u.cnic, u.role,
            u.is_verified, u.is_active, u.failed_attempts, u.locked_until, u.created_at,
            np.push_alerts, np.email_digest, np.sms_alerts,
            np.quiet_hours_start, np.quiet_hours_end
     FROM users u
     LEFT JOIN notification_preferences np ON np.user_id = u.id
     WHERE u.id = $1`,
    [id],
  );
  return rows[0] || null;
}

async function setUserStatus(id, isActive) {
  const { rows } = await query(
    `UPDATE users SET is_active = $2, updated_at = NOW()
     WHERE id = $1
     RETURNING id, full_name, email, role, is_active, is_verified`,
    [id, isActive],
  );
  return rows[0] || null;
}

async function getStats() {
  const { rows } = await query(`
    SELECT
      COUNT(*)                                       AS total,
      COUNT(*) FILTER (WHERE is_active = TRUE)      AS active,
      COUNT(*) FILTER (WHERE is_active = FALSE)     AS inactive,
      COUNT(*) FILTER (WHERE is_verified = FALSE)   AS unverified,
      COUNT(*) FILTER (WHERE role = 'landowner')    AS landowners,
      COUNT(*) FILTER (WHERE role = 'manager')      AS managers,
      COUNT(*) FILTER (WHERE role = 'worker')       AS workers,
      COUNT(*) FILTER (WHERE role = 'admin')        AS admins,
      COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') AS new_this_week
    FROM users
  `);
  return rows[0];
}

module.exports = { listUsers, getUserById, setUserStatus, getStats };