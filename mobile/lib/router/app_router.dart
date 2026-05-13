import 'package:go_router/go_router.dart';
import '../features/scan/screens/plant_disease_scan_screen.dart';

import '../providers/auth_provider.dart';
import '../data/models/parcel_model.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/change_email_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/forgot_password_otp_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/manager_home_screen.dart';
import '../features/home/screens/worker_home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/profile/screens/notification_prefs_screen.dart';
import '../features/profile/screens/account_settings_screen.dart';
import '../features/parcels/screens/land_portfolio_screen.dart';
import '../features/parcels/screens/register_parcel_screen.dart';
import '../features/parcels/screens/parcel_detail_screen.dart';
import '../features/parcels/screens/crop_plan_screen.dart';

class AppRouter {
  static const splash          = '/';
  static const welcome         = '/welcome';
  static const login           = '/login';
  static const register        = '/register';
  static const otp             = '/otp';
  static const changeEmail     = '/change-email';
  static const forgotPassword    = '/forgot-password';
  static const resetPassword     = '/reset-password';
  static const forgotPasswordOtp = '/forgot-password-otp'; // 3-step OTP flow
  static const home            = '/home';
  static const profile         = '/profile';
  static const editProfile     = '/profile/edit';
  static const changePassword  = '/profile/password';
  static const notifications   = '/profile/notifications';
  static const accountSettings = '/profile/account';

  // Scan
  static const plantDiseaseScan = '/scan/plant-disease';

  // Role-specific home routes
  static const managerHome     = '/manager-home';
  static const workerHome      = '/worker-home';

  // Module 2 — Land Portfolio
  static const landPortfolio   = '/parcels';
  static const registerParcel  = '/parcels/new';
  static const parcelDetail    = '/parcels/detail';
  static const cropPlan        = '/parcels/crop-plan';

  /// Call once and store the result — do not recreate on every build.
  static GoRouter createRouter(AuthProvider auth) => GoRouter(
    initialLocation: splash,
    // Re-evaluate redirect whenever AuthProvider notifies (login / logout / checkAuth)
    refreshListenable: auth,
    redirect: (ctx, state) {
      final isAuth    = auth.state == AuthState.authenticated;
      final isUnknown = auth.state == AuthState.unknown;
      final loc       = state.matchedLocation;

      // Still checking stored tokens — stay on splash
      if (isUnknown) return loc == splash ? null : splash;

      final publicRoutes = {
        welcome, login, register, otp, changeEmail, forgotPassword,
        resetPassword, forgotPasswordOtp, splash,
      };
      if (isAuth  && publicRoutes.contains(loc)) return home;
      if (!isAuth && loc == home)                return welcome;
      return null;
    },
    routes: [
      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(path: splash,        builder: (_, __) => const SplashScreen()),
      GoRoute(path: welcome,       builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: login,         builder: (_, __) => const LoginScreen()),
      GoRoute(path: register,      builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: otp,
        builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(path: changeEmail, builder: (_, __) => const ChangeEmailScreen()),
      GoRoute(path: forgotPassword,    builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: forgotPasswordOtp, builder: (_, __) => const ForgotPasswordOtpScreen()),
      GoRoute(
        path: resetPassword,
        builder: (_, state) => ResetPasswordScreen(token: state.extra as String? ?? ''),
      ),

      // ── Main ─────────────────────────────────────────────────────────────
      GoRoute(path: home,            builder: (_, __) => const HomeScreen()),
      GoRoute(path: managerHome,     builder: (_, __) => const ManagerHomeScreen()),
      GoRoute(path: workerHome,      builder: (_, __) => const WorkerHomeScreen()),
      GoRoute(path: plantDiseaseScan, builder: (_, __) => const PlantDiseaseScanScreen()),
      GoRoute(path: profile,         builder: (_, __) => const ProfileScreen()),
      GoRoute(path: editProfile,     builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: changePassword,  builder: (_, __) => const ChangePasswordScreen()),
      GoRoute(path: notifications,   builder: (_, __) => const NotificationPrefsScreen()),
      GoRoute(path: accountSettings, builder: (_, __) => const AccountSettingsScreen()),

      // ── Module 2: Land Portfolio ──────────────────────────────────────────
      GoRoute(path: landPortfolio,   builder: (_, __) => const LandPortfolioScreen()),
      GoRoute(path: registerParcel,  builder: (_, __) => const RegisterParcelScreen()),
      GoRoute(
        path: parcelDetail,
        builder: (_, state) => ParcelDetailScreen(parcel: state.extra as ParcelModel),
      ),
      GoRoute(
        path: cropPlan,
        builder: (_, state) => CropPlanScreen(parcel: state.extra as ParcelModel),
      ),
    ],
  );
}
