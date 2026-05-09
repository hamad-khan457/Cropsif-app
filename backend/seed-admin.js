require('dotenv').config();
const bcrypt = require('bcrypt');
const { pool } = require('./src/config/database');

const ADMIN_EMAIL    = 'admin@cropsify.com';
const ADMIN_PASSWORD = 'Admin@1234';

async function seedAdmin() {
  // Ensure the role check constraint includes 'admin' (handles DBs migrated before admin was added)
  await pool.query(`
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'users' AND constraint_name = 'users_role_check'
      ) THEN
        ALTER TABLE users DROP CONSTRAINT users_role_check;
      END IF;
      ALTER TABLE users ADD CONSTRAINT users_role_check
        CHECK (role IN ('landowner','manager','worker','admin'));
    END$$;
  `);

  const { rows } = await pool.query(
    'SELECT id FROM users WHERE email = $1',
    [ADMIN_EMAIL],
  );

  if (rows.length > 0) {
    console.log('Admin already exists — skipping seed.');
    await pool.end();
    return;
  }

  const hash = await bcrypt.hash(ADMIN_PASSWORD, 12);

  await pool.query(
    `INSERT INTO users
       (full_name, email, phone, cnic, password_hash, role, is_verified, is_active)
     VALUES ($1, $2, $3, $4, $5, 'admin', TRUE, TRUE)`,
    ['Super Admin', ADMIN_EMAIL, '03000000000', '00000-0000000-0', hash],
  );

  console.log('✓ Admin seeded');
  console.log('  Email   :', ADMIN_EMAIL);
  console.log('  Password:', ADMIN_PASSWORD);
  await pool.end();
}

seedAdmin().catch(err => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});