import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form     = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm  = TextEditingController();
  bool _done      = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(
      token: widget.token,
      newPassword: _password.text,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _done = true);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('New Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _done
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 80, color: AppTheme.primary),
                      const SizedBox(height: 20),
                      const Text(
                        'Password Reset!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your password has been changed. You can now sign in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 36),
                      ElevatedButton(
                        onPressed: () => context.go(AppRouter.login),
                        child: const Text('Go to Sign In'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Create New Password',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your new password must be at least 8 characters, include one uppercase letter and one number.',
                        style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      AuthTextField(
                        controller: _password,
                        label: 'New Password',
                        obscure: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _confirm,
                        label: 'Confirm Password',
                        obscure: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        textInputAction: TextInputAction.done,
                        validator: (v) => Validators.confirmPassword(v, _password.text),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 32),
                      AuthButton(
                        label: 'Reset Password',
                        loading: auth.loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}