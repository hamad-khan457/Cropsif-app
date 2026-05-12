class ApiConstants {
  // Physical device: use LAN IP of the dev machine (192.168.100.239)
  // Android emulator: use 10.0.2.2 instead
  static const String _base = 'http://192.168.100.239:5000/api/v1';

  // Auth
  static const String register        = '$_base/auth/register';
  static const String verifyOtp       = '$_base/auth/verify-otp';
  static const String resendOtp       = '$_base/auth/resend-otp';
  static const String login           = '$_base/auth/login';
  static const String refresh         = '$_base/auth/refresh';
  static const String logout          = '$_base/auth/logout';
  static const String forgotPassword    = '$_base/auth/forgot-password';
  static const String resetPassword     = '$_base/auth/reset-password';
  // OTP-based password reset (mobile flow)
  static const String forgotPasswordOtp = '$_base/auth/forgot-password-otp';
  static const String resetPasswordOtp  = '$_base/auth/reset-password-otp';

  // Users
  static const String me                  = '$_base/users/me';
  static const String mePassword          = '$_base/users/me/password';
  static const String meNotifications     = '$_base/users/me/notifications';
  static const String meExport            = '$_base/users/me/export';

  // Parcels (Module 2)
  static const String parcels             = '$_base/parcels';
  static String parcel(String id)         => '$_base/parcels/$id';
  static String parcelHistory(String id)  => '$_base/parcels/$id/history';

  // Scan (ML)
  static const String scanPredict         = '$_base/scan/predict';
}
