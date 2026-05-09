import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/cropsify_app_bar.dart';
import '../../../core/widgets/cropsify_logo.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form     = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth  = context.read<AuthProvider>();
    final email = _email.text.trim();
    final ok    = await auth.login(email: email, password: _password.text);
    if (!mounted) return;
    if (ok) { context.go(AppRouter.home); return; }

    final code = auth.errorCode;
    final msg  = auth.error ?? '';
    final notVerified = code == 403 ||
        msg.toLowerCase().contains('not verified') ||
        msg.toLowerCase().contains('verify') ||
        msg.toLowerCase().contains('inactive');

    if (notVerified) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('Email Not Verified', 'ای میل تصدیق نہیں ہوئی')),
          content: Text(context.tr(
            'Your account has not been verified yet. Please check your email for the OTP.',
            'آپ کا اکاؤنٹ ابھی تصدیق نہیں ہوا۔ براہ کرم ای میل میں OTP چیک کریں۔',
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr('Cancel', 'منسوخ'))),
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); context.go(AppRouter.otp, extra: email); },
              child: Text(context.tr('Enter OTP', 'OTP درج کریں')),
            ),
          ],
        ),
      );
      return;
    }

    final displayMsg = (code == 401)
        ? context.tr('Invalid email or password.', 'ای میل یا پاس ورڈ غلط ہے۔')
        : msg;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(displayMsg), backgroundColor: AppTheme.error));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: CropsifyAppBar(
        titleEn: 'Sign In',
        titleUr: 'لاگ ان',
        onBack:  () => context.go(AppRouter.welcome),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Center(child: CropsifyLogo(size: 80)),
                const SizedBox(height: 24),
                Text(
                  context.tr('Welcome back!', 'خوش آمدید!'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('Sign in to manage your farms',
                      'اپنے فارم منظم کرنے کے لیے لاگ ان کریں'),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  controller:   _email,
                  label:        context.tr('Email Address', 'ای میل پتہ'),
                  hint:         'farmer@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon:   const Icon(Icons.email_outlined),
                  validator:    Validators.email,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller:      _password,
                  label:           context.tr('Password', 'پاس ورڈ'),
                  obscure:         true,
                  prefixIcon:      const Icon(Icons.lock_outline),
                  validator: (v) => v == null || v.isEmpty
                      ? context.tr('Password is required', 'پاس ورڈ درج کریں')
                      : null,
                  textInputAction:  TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go(AppRouter.forgotPasswordOtp),
                    child: Text(
                        context.tr('Forgot Password?', 'پاس ورڈ بھول گئے؟')),
                  ),
                ),
                const SizedBox(height: 20),
                AuthButton(
                  label:     context.tr('Sign In', 'لاگ ان کریں'),
                  loading:   auth.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.tr("Don't have an account?",
                        'اکاؤنٹ نہیں ہے؟'),
                        style: const TextStyle(color: AppTheme.textSecondary)),
                    TextButton(
                      onPressed: () => context.go(AppRouter.register),
                      child: Text(context.tr('Register', 'رجسٹر کریں')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
