import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/cropsify_app_bar.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

/// Three-step password reset:
///   Step 0 — Enter email → sends OTP
///   Step 1 — Enter 6-digit OTP received on email
///   Step 2 — Enter new password + confirm
class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({super.key});

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  int _step = 0;

  // Step 0
  final _emailForm = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  // Step 1
  final _otpCtrl = TextEditingController();
  String _otp    = '';
  int  _countdown = 60;
  Timer? _timer;

  // Step 2
  final _pwForm    = GlobalKey<FormState>();
  final _pwCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePw  = true;
  bool _obscureConf = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _t => context.read<LanguageProvider>().isUrdu
      ? 'ur' : 'en';
  String _l(String en, String ur) =>
      _t == 'ur' ? ur : en;

  // ── Step 0: send OTP ────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!_emailForm.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.sendPasswordResetOtp(_emailCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _step = 1);
      _startCountdown();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to send OTP'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> _resendOtp() async {
    final auth = context.read<AuthProvider>();
    final ok   = await auth.sendPasswordResetOtp(_emailCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      _otpCtrl.clear();
      setState(() => _otp = '');
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l('Reset code resent to your email.', 'ری سیٹ کوڈ ای میل پر بھیج دیا گیا۔')),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  // ── Step 1: verify OTP ─────────────────────────────────────────────────────
  void _verifyOtp() {
    if (_otp.length == 6) {
      setState(() => _step = 2);
    }
  }

  // ── Step 2: reset password ─────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    if (!_pwForm.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.resetPasswordWithOtp(
      email:       _emailCtrl.text.trim(),
      otp:         _otp,
      newPassword: _pwCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l(
            'Password reset successfully! Please log in.',
            'پاس ورڈ کامیابی سے تبدیل ہو گیا! لاگ ان کریں۔',
          )),
          backgroundColor: AppTheme.primary,
        ),
      );
      context.go(AppRouter.login);
    } else {
      // OTP might be wrong — go back to step 1
      final err = auth.error ?? '';
      if (err.toLowerCase().contains('invalid') ||
          err.toLowerCase().contains('expired')) {
        setState(() { _step = 1; _otpCtrl.clear(); _otp = ''; });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: CropsifyAppBar(
        titleEn: 'Reset Password',
        titleUr: 'پاس ورڈ ری سیٹ',
        onBack: () {
          if (_step > 0) {
            setState(() { _step--; _timer?.cancel(); });
          } else {
            context.go(AppRouter.login);
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _step == 0
                ? _buildEmailStep(auth)
                : _step == 1
                    ? _buildOtpStep(auth)
                    : _buildNewPasswordStep(auth),
          ),
        ),
      ),
    );
  }

  // ── Step 0 UI ──────────────────────────────────────────────────────────────
  Widget _buildEmailStep(AuthProvider auth) {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _StepHeader(
            icon:  Icons.lock_reset,
            title: _l('Forgot Password', 'پاس ورڈ بھول گئے؟'),
            sub:   _l(
              'Enter your registered email. We\'ll send a 6-digit reset code.',
              'اپنا رجسٹرڈ ای میل درج کریں۔ ہم 6 ہندسوں کا ری سیٹ کوڈ بھیجیں گے۔',
            ),
          ),
          const SizedBox(height: 32),
          AuthTextField(
            controller:    _emailCtrl,
            label:         _l('Email Address', 'ای میل پتہ'),
            hint:          'farmer@example.com',
            keyboardType:  TextInputType.emailAddress,
            prefixIcon:    const Icon(Icons.email_outlined),
            validator:     Validators.email,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendOtp(),
          ),
          const SizedBox(height: 28),
          AuthButton(
            label:     _l('Send Reset Code', 'ری سیٹ کوڈ بھیجیں'),
            loading:   auth.loading,
            onPressed: _sendOtp,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRouter.login),
              child: Text(_l('Back to Sign In', 'واپس لاگ ان')),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1 UI ──────────────────────────────────────────────────────────────
  Widget _buildOtpStep(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        _StepHeader(
          icon:  Icons.mark_email_unread_outlined,
          title: _l('Enter Reset Code', 'ری سیٹ کوڈ درج کریں'),
          sub:   _l(
            'We sent a 6-digit code to\n${_emailCtrl.text}',
            'ہم نے 6 ہندسوں کا کوڈ بھیجا:\n${_emailCtrl.text}',
          ),
        ),
        const SizedBox(height: 36),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              error: AppTheme.error,
              secondary: AppTheme.primary,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: InputBorder.none,
            ),
          ),
          child: PinCodeTextField(
            appContext:   context,
            length:       6,
            controller:   _otpCtrl,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            cursorColor:  AppTheme.primary,
            autovalidateMode: AutovalidateMode.disabled,
            textStyle: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            pinTheme: PinTheme(
              shape:            PinCodeFieldShape.box,
              borderRadius:     BorderRadius.circular(12),
              fieldHeight:      56,
              fieldWidth:       46,
              borderWidth:      1.5,
              activeFillColor:  Colors.white,
              selectedFillColor: Colors.white,
              inactiveFillColor: Colors.white,
              activeColor:      AppTheme.primary,
              selectedColor:    AppTheme.primary,
              inactiveColor:    const Color(0xFFE0E0E0),
              errorBorderColor: AppTheme.error,
            ),
            enableActiveFill: true,
            onChanged: (v) => setState(() => _otp = v),
            onCompleted: (_) => _verifyOtp(),
          ),
        ),
        const SizedBox(height: 28),
        AuthButton(
          label:     _l('Verify Code', 'کوڈ تصدیق کریں'),
          loading:   auth.loading,
          onPressed: _otp.length == 6 ? _verifyOtp : null,
        ),
        const SizedBox(height: 20),
        if (_countdown > 0)
          Text(
            _l('Resend in ${_countdown}s', '${_countdown}s میں دوبارہ بھیجیں'),
            style: const TextStyle(color: AppTheme.textSecondary),
          )
        else
          TextButton(
            onPressed: auth.loading ? null : _resendOtp,
            child: Text(_l('Resend Code', 'کوڈ دوبارہ بھیجیں')),
          ),
      ],
    );
  }

  // ── Step 2 UI ──────────────────────────────────────────────────────────────
  Widget _buildNewPasswordStep(AuthProvider auth) {
    return Form(
      key: _pwForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _StepHeader(
            icon:  Icons.lock_outline,
            title: _l('New Password', 'نیا پاس ورڈ'),
            sub:   _l(
              'Create a strong new password for your account.',
              'اپنے اکاؤنٹ کے لیے ایک مضبوط نیا پاس ورڈ بنائیں۔',
            ),
          ),
          const SizedBox(height: 32),
          AuthTextField(
            controller: _pwCtrl,
            label:      _l('New Password', 'نیا پاس ورڈ'),
            obscure:    _obscurePw,
            prefixIcon: const Icon(Icons.lock_outline),
            validator:  Validators.password,
          ),
          const SizedBox(height: 6),
          Text(
            _l(
              'Min 8 chars, one uppercase letter, one number',
              'کم از کم 8 حروف، ایک بڑا حرف، ایک نمبر',
            ),
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller:      _confirmCtrl,
            label:           _l('Confirm Password', 'پاس ورڈ کی تصدیق'),
            obscure:         _obscureConf,
            prefixIcon:      const Icon(Icons.lock_outline),
            textInputAction: TextInputAction.done,
            validator:       (v) => v != _pwCtrl.text
                ? _l('Passwords do not match', 'پاس ورڈ مماثل نہیں')
                : null,
            onFieldSubmitted: (_) => _resetPassword(),
          ),
          const SizedBox(height: 32),
          AuthButton(
            label:     _l('Reset Password', 'پاس ورڈ ری سیٹ کریں'),
            loading:   auth.loading,
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   sub;
  const _StepHeader({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color:  AppTheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 36, color: AppTheme.primary),
      ),
      const SizedBox(height: 20),
      Text(title,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary)),
      const SizedBox(height: 8),
      Text(sub,
          style: const TextStyle(
              color: AppTheme.textSecondary, height: 1.5)),
    ],
  );
}
