import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form  = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent   = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(_email.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
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
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _SuccessView(email: _email.text) : _FormView(
            form: _form,
            email: _email,
            loading: auth.loading,
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> form;
  final TextEditingController email;
  final bool loading;
  final VoidCallback onSubmit;

  const _FormView({
    required this.form, required this.email,
    required this.loading, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset, size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Reset Password',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your email address and we\'ll send you a password reset link.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          AuthTextField(
            controller: email,
            label: 'Email Address',
            hint: 'farmer@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: Validators.email,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 28),
          AuthButton(label: 'Send Reset Link', loading: loading, onPressed: onSubmit),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, size: 56, color: AppTheme.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email Sent!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'If $email is registered, you\'ll receive a password reset link shortly.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => context.go(AppRouter.login),
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }
}