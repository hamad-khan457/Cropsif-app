// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
//
// import 'core/theme/app_theme.dart';
// import 'providers/auth_provider.dart';
// import 'providers/language_provider.dart';
// import 'providers/parcel_provider.dart';
// import 'providers/user_provider.dart';
// import 'router/app_router.dart';
//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//     statusBarColor: Colors.transparent,
//     statusBarIconBrightness: Brightness.light,
//   ));
//   runApp(const CropsifyApp());
// }
//
// class CropsifyApp extends StatelessWidget {
//   const CropsifyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => UserProvider()),
//         ChangeNotifierProvider(create: (_) => LanguageProvider()),
//         ChangeNotifierProvider(create: (_) => ParcelProvider()),
//       ],
//       // _AppRoot holds the router as stable state — it is NEVER recreated
//       // when LanguageProvider changes, so the router does not fire redirects.
//       child: const _AppRoot(),
//     );
//   }
// }
//
// class _AppRoot extends StatefulWidget {
//   const _AppRoot();
//   @override
//   State<_AppRoot> createState() => _AppRootState();
// }
//
// class _AppRootState extends State<_AppRoot> {
//   GoRouter? _router;
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();
//     final lang = context.watch<LanguageProvider>();
//
//     // Create router ONCE — the auth ChangeNotifier is passed as refreshListenable.
//     // After creation, auth.notifyListeners() re-evaluates the redirect without
//     // recreating the router. LanguageProvider changes only rebuild the builder
//     // below, never the router itself.
//     _router ??= AppRouter.createRouter(auth);
//
//     return MaterialApp.router(
//       title:                      'Cropsify',
//       theme:                      AppTheme.light,
//       debugShowCheckedModeBanner: false,
//       routerConfig:               _router!,
//       // Apply global RTL/LTR based on language preference
//       builder: (_, child) => Directionality(
//         textDirection:
//             lang.isUrdu ? TextDirection.rtl : TextDirection.ltr,
//         child: child!,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/api_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/parcel_provider.dart';
import 'providers/user_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConstants.init(); // auto-detects emulator vs real device
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CropsifyApp());
}

class CropsifyApp extends StatelessWidget {
  const CropsifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ParcelProvider()),
      ],
      // _AppRoot holds the router as stable state — it is NEVER recreated
      // when LanguageProvider changes, so the router does not fire redirects.
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lang = context.watch<LanguageProvider>();

    // Create router ONCE — the auth ChangeNotifier is passed as refreshListenable.
    // After creation, auth.notifyListeners() re-evaluates the redirect without
    // recreating the router. LanguageProvider changes only rebuild the builder
    // below, never the router itself.
    _router ??= AppRouter.createRouter(auth);

    return MaterialApp.router(
      title:                      'Cropsify',
      theme:                      AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig:               _router!,
      // Apply global RTL/LTR based on language preference
      builder: (_, child) => Directionality(
        textDirection:
        lang.isUrdu ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
    );
  }
}
//flutter run --dart-define=BACKEND_HOST=192.168.100.239