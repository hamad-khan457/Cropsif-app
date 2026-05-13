import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/cropsify_app_bar.dart';
import '../../../router/app_router.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _form     = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final email  = _emailCtrl.text.trim();
    final auth   = context.read<AuthProvider>();
    final isUrdu = context.read<LanguageProvider>().isUrdu;

    final result = await auth.checkEmailForChange(email);
    if (!mounted) return;

    switch (result) {
      case 'otp_sent':
        // Pending account found — OTP was sent to this email
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isUrdu
              ? 'تصدیقی کوڈ $email پر بھیج دیا گیا'
              : 'Verification code sent to $email'),
          backgroundColor: AppTheme.primary,
        ));
        context.go(AppRouter.otp, extra: email);

      case 'already_registered':
        // Fully verified account exists — redirect to login
        _showRegisteredDialog(email, isUrdu);

      case 'not_found':
        // Email never registered — go back to register to fill the form again
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isUrdu
              ? 'یہ ای میل رجسٹرڈ نہیں۔ براہ کرم رجسٹریشن فارم بھریں۔'
              : 'Email not registered. Please complete the registration form.'),
        ));
        context.go(AppRouter.register);

      default:
        if (auth.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(auth.error!),
            backgroundColor: AppTheme.error,
          ));
        }
    }
  }

  void _showRegisteredDialog(String email, bool isUrdu) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.info_outline, color: AppTheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            isUrdu ? 'ای میل پہلے سے موجود' : 'Email Already Registered',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ]),
        content: Text(
          isUrdu
              ? '$email پہلے سے رجسٹرڈ ہے۔ براہ کرم لاگ ان کریں۔'
              : '$email is already registered.\nPlease log in with this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isUrdu ? 'واپس' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRouter.login);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(isUrdu ? 'لاگ ان' : 'Go to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: CropsifyAppBar(
        titleEn: 'Change Email',
        titleUr: 'ای میل تبدیل کریں',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Icon
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      size: 40, color: AppTheme.primary),
                ),
                const SizedBox(height: 20),

                Text(
                  context.tr('Enter your new email', 'نئی ای میل درج کریں'),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'We\'ll check if this email is available and send you a new verification code.',
                    'ہم چیک کریں گے کہ یہ ای میل دستیاب ہے یا نہیں اور نیا تصدیقی کوڈ بھیجیں گے۔',
                  ),
                  style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                AuthTextField(
                  controller:   _emailCtrl,
                  label:        context.tr('New Email Address', 'نئی ای میل'),
                  hint:         'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon:   const Icon(Icons.email_outlined),
                  validator:    Validators.email,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 32),

                AuthButton(
                  label:     context.tr('Continue', 'جاری رکھیں'),
                  loading:   auth.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(context.tr('Cancel', 'منسوخ کریں')),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
