class AppConstants {
  static const String appName     = 'Cropsify';
  static const String tagline     = 'Intelligent Farm Management';

  // Secure storage keys
  static const String accessToken  = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId       = 'user_id';
  static const String userRole     = 'user_role';

  // Roles
  static const String roleLandowner = 'landowner';
  static const String roleManager   = 'manager';
  static const String roleWorker    = 'worker';
  static const String roleAdmin     = 'admin';

  // OTP resend cooldown
  static const int otpResendCooldownSeconds = 60;
}