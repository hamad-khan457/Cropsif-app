const { query } = require('../../config/database');

// ─── Profile ──────────────────────────────────────────────────────────────────

async function getProfile(userId) {
  const { rows } = await query(
    `SELECT u.id, u.full_name, u.email, u.phone, u.cnic, u.role,
            u.is_verified, u.is_active, u.created_at,
            np.push_alerts, np.email_digest, np.sms_alerts,
            np.quiet_hours_start, np.quiet_hours_end
     FROM users u
     LEFT JOIN notification_preferences np ON np.user_id = u.id
     WHERE u.id = $1`,
    [userId],
  );
  return rows[0] || null;
}

async function updateProfile(userId, { fullName, phone }) {
  const { rows } = await query(
    `UPDATE users
     SET full_name = COALESCE($2, full_name),
         phone     = COALESCE($3, phone),
         updated_at = NOW()
     WHERE id = $1
     RETURNING id, full_name, email, phone, role`,
    [userId, fullName || null, phone || null],
  );
  return rows[0];
}

async function deactivateUser(userId) {
  await query(
    `UPDATE users SET is_active = FALSE, updated_at = NOW() WHERE id = $1`,
    [userId],
  );
}

async function exportUserData(userId) {
  const { rows } = await query(
    `SELECT u.id, u.full_name, u.email, u.phone, u.cnic, u.role, u.created_at,
            np.push_alerts, np.email_digest, np.sms_alerts
     FROM users u
     LEFT JOIN notification_preferences np ON np.user_id = u.id
     WHERE u.id = $1`,
    [userId],
  );
  return rows[0] || null;
}

// ─── Notification Preferences ─────────────────────────────────────────────────

async function upsertNotificationPrefs(userId, { pushAlerts, emailDigest, smsAlerts, quietHoursStart, quietHoursEnd }) {
  const { rows } = await query(
    `INSERT INTO notification_preferences
       (user_id, push_alerts, email_digest, sms_alerts, quiet_hours_start, quiet_hours_end)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (user_id) DO UPDATE SET
       push_alerts        = EXCLUDED.push_alerts,
       email_digest       = EXCLUDED.email_digest,
       sms_alerts         = EXCLUDED.sms_alerts,
       quiet_hours_start  = EXCLUDED.quiet_hours_start,
       quiet_hours_end    = EXCLUDED.quiet_hours_end,
       updated_at         = NOW()
     RETURNING *`,
    [userId, pushAlerts, emailDigest, smsAlerts, quietHoursStart || null, quietHoursEnd || null],
  );
  return rows[0];
}

async function getNotificationPrefs(userId) {
  const { rows } = await query(
    `SELECT * FROM notification_preferences WHERE user_id = $1`,
    [userId],
  );
  return rows[0] || null;
}

module.exports = {
  getProfile,
  updateProfile,
  deactivateUser,
  exportUserData,
  upsertNotificationPrefs,
  getNotificationPrefs,
};