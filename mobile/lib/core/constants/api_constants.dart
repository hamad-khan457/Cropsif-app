// // class ApiConstants {
// //   // Physical device: use LAN IP of the dev machine (192.168.100.239)
// //   // Android emulator: use 10.0.2.2 instead
// //   static const String _base = 'http://192.168.100.239:5000/api/v1';
// //
// //   // Auth
// //   static const String register        = '$_base/auth/register';
// //   static const String verifyOtp       = '$_base/auth/verify-otp';
// //   static const String resendOtp       = '$_base/auth/resend-otp';
// //   static const String login           = '$_base/auth/login';
// //   static const String refresh         = '$_base/auth/refresh';
// //   static const String logout          = '$_base/auth/logout';
// //   static const String forgotPassword    = '$_base/auth/forgot-password';
// //   static const String resetPassword     = '$_base/auth/reset-password';
// //   // OTP-based password reset (mobile flow)
// //   static const String forgotPasswordOtp = '$_base/auth/forgot-password-otp';
// //   static const String resetPasswordOtp  = '$_base/auth/reset-password-otp';
// //
// //   // Users
// //   static const String me                  = '$_base/users/me';
// //   static const String mePassword          = '$_base/users/me/password';
// //   static const String meNotifications     = '$_base/users/me/notifications';
// //   static const String meExport            = '$_base/users/me/export';
// //
// //   // Parcels (Module 2)
// //   static const String parcels             = '$_base/parcels';
// //   static String parcel(String id)         => '$_base/parcels/$id';
// //   static String parcelHistory(String id)  => '$_base/parcels/$id/history';
// //
// //   // Scan (ML)
// //   static const String scanPredict         = '$_base/scan/predict';
// // }
// class ApiConstants {
//   // ✅ Auto-works for emulator and physical device
//   static const String _emulatorBase = 'http://10.0.2.2:5000/api/v1';
//   static const String _deviceBase   = 'http://10.76.162.150:5000/api/v1';
//
//   // Change to _deviceBase when running on real phone
//   static String get _base => _emulatorBase;
//
//   // Auth
//   static String get register          => '$_base/auth/register';
//   static String get verifyOtp         => '$_base/auth/verify-otp';
//   static String get resendOtp         => '$_base/auth/resend-otp';
//   static String get login             => '$_base/auth/login';
//   static String get refresh           => '$_base/auth/refresh';
//   static String get logout            => '$_base/auth/logout';
//   static String get forgotPassword    => '$_base/auth/forgot-password';
//   static String get resetPassword     => '$_base/auth/reset-password';
//   static String get forgotPasswordOtp => '$_base/auth/forgot-password-otp';
//   static String get resetPasswordOtp  => '$_base/auth/reset-password-otp';
//
//   // Users
//   static String get me                => '$_base/users/me';
//   static String get mePassword        => '$_base/users/me/password';
//   static String get meNotifications   => '$_base/users/me/notifications';
//   static String get meExport          => '$_base/users/me/export';
//
//   // Parcels
//   static String get parcels           => '$_base/parcels';
//   static String parcel(String id)        => '$_base/parcels/$id';
//   static String parcelHistory(String id) => '$_base/parcels/$id/history';
//
//   // Scan
//   static String get scanPredict       => '$_base/scan/predict';
// }
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _emulatorHost = '10.0.2.2';
  static const int    _port         = 5000;

  // Injected at build time: flutter run --dart-define=BACKEND_HOST=<your-pc-ip>
  // Use run_mobile.ps1 (Windows) or run_mobile.sh (Mac/Linux) — they auto-detect your IP.
  static const String _buildTimeHost = String.fromEnvironment('BACKEND_HOST');

  /// Call this once in main() before runApp()
  static late final String base;

  static Future<void> init() async {
    if (kIsWeb) {
      base = '/api/v1';
      return;
    }

    if (Platform.isAndroid) {
      if (_buildTimeHost.isNotEmpty) {
        // Use the IP that was provided at build time (works on any network).
        base = 'http://$_buildTimeHost:$_port/api/v1';
      } else {
        // Fallback: detect emulator vs physical device at runtime.
        bool isEmulator = false;
        try {
          final result = await Process.run('getprop', ['ro.build.fingerprint']);
          final fingerprint = result.stdout.toString().toLowerCase();
          isEmulator = fingerprint.contains('generic') ||
              fingerprint.contains('sdk_gphone') ||
              fingerprint.contains('emulator') ||
              fingerprint.contains('x86');
        } catch (_) {
          isEmulator = false;
        }
        // No host provided — emulator works, physical device will likely fail.
        // Run via run_mobile.ps1 to fix this automatically.
        base = isEmulator
            ? 'http://$_emulatorHost:$_port/api/v1'
            : 'http://MISSING_HOST:$_port/api/v1';
      }
    } else if (Platform.isIOS) {
      base = _buildTimeHost.isNotEmpty
          ? 'http://$_buildTimeHost:$_port/api/v1'
          : 'http://localhost:$_port/api/v1';
    } else {
      base = 'http://$_buildTimeHost:$_port/api/v1';
    }

    debugPrint('🌐 API base URL: $base');
  }

  // ── Endpoints ───────────────────────────────────────────────────────────────

  // Auth
  static String get register          => '$base/auth/register';
  static String get verifyOtp         => '$base/auth/verify-otp';
  static String get resendOtp         => '$base/auth/resend-otp';
  static String get login             => '$base/auth/login';
  static String get refresh           => '$base/auth/refresh';
  static String get logout            => '$base/auth/logout';
  static String get forgotPassword    => '$base/auth/forgot-password';
  static String get resetPassword     => '$base/auth/reset-password';
  static String get forgotPasswordOtp => '$base/auth/forgot-password-otp';
  static String get resetPasswordOtp  => '$base/auth/reset-password-otp';

  // Users
  static String get me                => '$base/users/me';
  static String get mePassword        => '$base/users/me/password';
  static String get meNotifications   => '$base/users/me/notifications';
  static String get meExport          => '$base/users/me/export';

  // Parcels
  static String get parcels           => '$base/parcels';
  static String parcel(String id)        => '$base/parcels/$id';
  static String parcelHistory(String id) => '$base/parcels/$id/history';

  // Scan (ML)
  static String get scanPredict       => '$base/scan/predict';
}