import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/widgets/cropsify_app_bar.dart';
import '../../../core/utils/validators.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../../auth/widgets/auth_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form    = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose(); _newPass.dispose(); _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final prov = context.read<UserProvider>();
    final ok = await prov.changePassword(
      currentPassword: _current.text,
      newPassword: _newPass.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(
              'Password changed successfully',
              'پاسورڈ کامیابی سے تبدیل ہوا')),
          backgroundColor: AppTheme.primary,
        ),
      );
      context.go(AppRouter.profile);
    } else if (prov.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.error!), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserProvider>();

    return Scaffold(
      appBar: CropsifyAppBar(
        titleEn: 'Change Password',
        titleUr: 'پاسورڈ تبدیل کریں',
        onBack: () => context.go(AppRouter.profile),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'Your new password must be at least 8 characters, include one uppercase letter and one number.',
                    'آپ کا نیا پاسورڈ کم از کم 8 حروف کا ہونا چاہیے، ایک بڑا حرف اور ایک نمبر شامل ہو۔',
                  ),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  controller: _current,
                  label: context.tr('Current Password', 'موجودہ پاسورڈ'),
                  obscure: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (v) => v == null || v.isEmpty
                      ? context.tr(
                          'Current password is required',
                          'موجودہ پاسورڈ ضروری ہے')
                      : null,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _newPass,
                  label: context.tr('New Password', 'نیا پاسورڈ'),
                  obscure: true,
                  prefixIcon: const Icon(Icons.lock_reset),
                  validator: Validators.password,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _confirm,
                  label:
                      context.tr('Confirm New Password', 'نئے پاسورڈ کی تصدیق کریں'),
                  obscure: true,
                  prefixIcon: const Icon(Icons.lock_reset),
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      Validators.confirmPassword(v, _newPass.text),
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 32),
                AuthButton(
                  label: context.tr('Change Password', 'پاسورڈ تبدیل کریں'),
                  loading: prov.loading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
