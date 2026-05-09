const nodemailer = require('nodemailer');

// Only add auth when credentials are actually provided (MailHog needs no auth)
const _auth = process.env.SMTP_USER
  ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
  : undefined;

const _port = parseInt(process.env.SMTP_PORT || '1025');

const transporter = nodemailer.createTransport({
  pool:           true,   // keep connections alive — prevents first-email delay
  maxConnections: 3,
  host:   process.env.SMTP_HOST || 'localhost',
  port:   _port,
  secure: _port === 465,          // true only for port 465 (SSL); 587 uses STARTTLS
  auth:   _auth,
  tls: { rejectUnauthorized: false },
});

const FROM = process.env.EMAIL_FROM || process.env.SMTP_FROM || 'noreply@cropsify.pk';

// Pre-warm SMTP connection so the first sendMail call is instant
transporter.verify()
  .then(() => console.log('[Email] SMTP connection ready'))
  .catch((err) => console.error('[Email] SMTP connection warning:', err.message));

async function sendOtpEmail(to, otp) {
  await transporter.sendMail({
    from: FROM,
    to,
    subject: 'Cropsify — Verify Your Account',
    html: `
      <h2>Cropsify Account Verification</h2>
      <p>Your one-time verification code is:</p>
      <h1 style="letter-spacing:8px;">${otp}</h1>
      <p>This code expires in <strong>3 minutes</strong>.</p>
      <p>If you did not request this, ignore this email.</p>
    `,
  });
}

async function sendPasswordResetEmail(to, resetLink) {
  await transporter.sendMail({
    from: FROM,
    to,
    subject: 'Cropsify — Reset Your Password',
    html: `
      <h2>Cropsify Password Reset</h2>
      <p>Click the link below to reset your password. This link is valid for <strong>15 minutes</strong>.</p>
      <a href="${resetLink}" style="display:inline-block;padding:12px 24px;background:#2d6a4f;color:#fff;border-radius:6px;text-decoration:none;">Reset Password</a>
      <p>If you did not request a reset, ignore this email.</p>
    `,
  });
}

async function sendPasswordResetOtpEmail(to, otp) {
  await transporter.sendMail({
    from: FROM,
    to,
    subject: 'Cropsify — Password Reset Code',
    html: `
      <h2>Cropsify Password Reset</h2>
      <p>Your password reset code is:</p>
      <h1 style="letter-spacing:8px;color:#2E7D32;">${otp}</h1>
      <p>This code expires in <strong>3 minutes</strong>. Do not share it with anyone.</p>
      <p>If you did not request a password reset, ignore this email.</p>
    `,
  });
}

async function sendManagerInviteEmail(to, inviteLink, inviterName) {
  await transporter.sendMail({
    from: FROM,
    to,
    subject: `${inviterName} has invited you to Cropsify`,
    html: `
      <h2>You have been invited to Cropsify</h2>
      <p><strong>${inviterName}</strong> has assigned you as a farm Manager on Cropsify.</p>
      <a href="${inviteLink}" style="display:inline-block;padding:12px 24px;background:#2d6a4f;color:#fff;border-radius:6px;text-decoration:none;">Accept Invitation</a>
      <p>This invitation expires in 48 hours.</p>
    `,
  });
}

module.exports = { sendOtpEmail, sendPasswordResetEmail, sendPasswordResetOtpEmail, sendManagerInviteEmail };