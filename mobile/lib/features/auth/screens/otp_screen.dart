import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/widgets/cropsify_app_bar.dart';
import '../widgets/auth_button.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  String _otp    = '';
  int _cd        = AppConstants.otpResendCooldownSeconds;
  Timer? _timer;

  @override
  void initState() { super.initState(); _startTimer(); }

  @override
  void dispose() { _timer?.cancel(); _otpCtrl.dispose(); super.dispose(); }

  void _startTimer() {
    _cd = AppConstants.otpResendCooldownSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { if (_cd > 0) { _cd--; } else { t.cancel(); } });
    });
  }

  Future<void> _verify() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr('Enter the 6-digit OTP', '6 ہندسوں کا OTP درج کریں'))));
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok   = await auth.verifyOtp(email: widget.email, otp: _otp);
    if (!mounted) return;
    if (ok) {
      context.go(AppRouter.home);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final ok   = await auth.resendOtp(widget.email);
    if (!mounted) return;
    if (ok) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr('OTP resent to your email', 'OTP آپ کی ای میل پر بھیج دیا گیا')),
        backgroundColor: AppTheme.primary));
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: CropsifyAppBar(
        titleEn: 'Verify Email',
        titleUr: 'ای میل تصدیق',
        onBack:  () => context.go(AppRouter.register),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 28),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    size: 40, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('Check your email', 'اپنی ای میل چیک کریں'),
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr(
                  'We sent a 6-digit verification code to',
                  'ہم نے 6 ہندسوں کا تصدیقی کوڈ بھیجا:',
                ),
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(widget.email,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppTheme.primary)),
              TextButton(
                onPressed: () => context.push(AppRouter.changeEmail),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.tr('Change email', 'ای میل تبدیل کریں'),
                  style: const TextStyle(
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // OTP input
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    error: AppTheme.error, secondary: AppTheme.primary),
                  inputDecorationTheme:
                      const InputDecorationTheme(border: InputBorder.none),
                ),
                child: PinCodeTextField(
                  appContext: context, length: 6,
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  cursorColor: AppTheme.primary,
                  autovalidateMode: AutovalidateMode.disabled,
                  textStyle: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 56, fieldWidth: 46, borderWidth: 1.5,
                    activeFillColor: Colors.white,
                    selectedFillColor: Colors.white,
                    inactiveFillColor: Colors.white,
                    activeColor: AppTheme.primary,
                    selectedColor: AppTheme.primary,
                    inactiveColor: const Color(0xFFE0E0E0),
                    errorBorderColor: AppTheme.error,
                  ),
                  enableActiveFill: true,
                  onChanged: (v) => setState(() => _otp = v),
                  onCompleted: (_) => _verify(),
                ),
              ),
              const SizedBox(height: 28),

              AuthButton(
                label:     context.tr('Verify', 'تصدیق کریں'),
                loading:   auth.loading,
                onPressed: _otp.length == 6 ? _verify : null,
              ),
              const SizedBox(height: 20),

              if (_cd > 0)
                Text(
                  context.tr('Resend code in ${_cd}s', '${_cd} سیکنڈ میں دوبارہ بھیجیں'),
                  style: const TextStyle(color: AppTheme.textSecondary),
                )
              else
                TextButton(
                  onPressed: auth.loading ? null : _resend,
                  child: Text(context.tr('Resend OTP', 'OTP دوبارہ بھیجیں')),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
