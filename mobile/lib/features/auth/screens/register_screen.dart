import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/cropsify_logo.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form     = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email    = TextEditingController();
  final _phone    = TextEditingController();
  final _cnic     = TextEditingController();
  final _password = TextEditingController();
  final _confirm  = TextEditingController();
  String _role    = AppConstants.roleLandowner;
  bool   _isUrdu  = false;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  void dispose() {
    _fullName.dispose(); _email.dispose();   _phone.dispose();
    _cnic.dispose();     _password.dispose(); _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth  = context.read<AuthProvider>();
    final email = _email.text.trim();
    final ok    = await auth.register(
      fullName: _fullName.text.trim(),
      email:    email,
      phone:    _phone.text.trim(),
      cnic:     _cnic.text.trim(),
      password: _password.text,
      role:     _role,
    );
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(
            'Registration successful! Please verify your email.',
            'رجسٹریشن کامیاب! براہ کرم اپنی ای میل تصدیق کریں۔',
          )),
          backgroundColor: AppTheme.primary,
        ),
      );
      context.go(AppRouter.otp, extra: email);
      return;
    }

    final code = auth.errorCode;
    final msg  = auth.error ?? '';
    final isAlreadyExists = code == 409 ||
        msg.toLowerCase().contains('already') ||
        msg.toLowerCase().contains('exists');

    if (isAlreadyExists) {
      if (!mounted) return;

      // Determine exactly which field is duplicated
      final isEmailConflict = msg.toLowerCase().contains('email');
      final isPhoneConflict = msg.toLowerCase().contains('phone');
      final isCnicConflict  = msg.toLowerCase().contains('cnic');

      final String fieldEn = isEmailConflict
          ? 'email address'
          : isPhoneConflict
              ? 'phone number'
              : isCnicConflict
                  ? 'CNIC'
                  : 'details';

      final String fieldUr = isEmailConflict
          ? 'ای میل پتہ'
          : isPhoneConflict
              ? 'فون نمبر'
              : isCnicConflict
                  ? 'شناختی کارڈ نمبر'
                  : 'معلومات';

      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_off_outlined, color: AppTheme.error),
              const SizedBox(width: 8),
              Text(_t('Already Registered', 'پہلے سے رجسٹرڈ')),
            ],
          ),
          content: Text(
            _t(
              'An account with this $fieldEn is already registered.\n\nPlease sign in to your existing account.',
              'اس $fieldUr سے پہلے سے اکاؤنٹ موجود ہے۔\n\nبراہ کرم اپنے موجودہ اکاؤنٹ میں لاگ ان کریں۔',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t('Cancel', 'منسوخ')),
            ),
            // Only show OTP option for email conflict — user may be unverified
            if (isEmailConflict)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(AppRouter.otp, extra: email);
                },
                child: Text(_t('Verify Email', 'ای میل تصدیق کریں')),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRouter.login);
              },
              child: Text(_t('Sign In', 'لاگ ان کریں')),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dir  = _isUrdu ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t('Create Account', 'اکاؤنٹ بنائیں')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRouter.welcome),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: InkWell(
                onTap: () => setState(() => _isUrdu = !_isUrdu),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white54),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _isUrdu ? 'EN' : 'اردو',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // Logo — already contains app name + tagline
                  const CropsifyLogo(size: 100),
                  const SizedBox(height: 16),
                  const SizedBox(height: 24),

                  // Role Selector
                  Align(
                    alignment: _isUrdu ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      _t('I am a', 'میں ہوں'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RoleSelector(
                    selected: _role,
                    isUrdu: _isUrdu,
                    onChanged: (r) => setState(() {
                      _role = r;
                      // Workers and managers are likely Urdu speakers — auto-switch
                      if (r == AppConstants.roleWorker || r == AppConstants.roleManager) {
                        _isUrdu = true;
                      } else if (r == AppConstants.roleLandowner) {
                        _isUrdu = false;
                      }
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Input fields always LTR so typing works naturally
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(
                      children: [
                        AuthTextField(
                          controller: _fullName,
                          label: _t('Full Name', 'پورا نام'),
                          hint: _t('Muhammad Ali Khan', 'محمد علی خان'),
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: Validators.fullName,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _email,
                          label: _t('Email Address', 'ای میل پتہ'),
                          hint: 'example@email.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _phone,
                          label: _t('Phone Number', 'فون نمبر'),
                          hint: '03001234567',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _cnic,
                          label: _t('CNIC', 'شناختی کارڈ نمبر'),
                          hint: '35202-1234567-8',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.credit_card_outlined),
                          validator: Validators.cnic,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _password,
                          label: _t('Password', 'پاس ورڈ'),
                          obscure: true,
                          prefixIcon: const Icon(Icons.lock_outline),
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _t(
                              'Min 8 chars, one uppercase letter, one number',
                              'کم از کم 8 حروف، ایک بڑا حرف، ایک نمبر',
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _confirm,
                          label: _t('Confirm Password', 'پاس ورڈ کی تصدیق'),
                          obscure: true,
                          prefixIcon: const Icon(Icons.lock_outline),
                          textInputAction: TextInputAction.done,
                          validator: (v) => Validators.confirmPassword(v, _password.text),
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  AuthButton(
                    label: _t('Create Account', 'اکاؤنٹ بنائیں'),
                    loading: auth.loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _t('Already have an account?', 'پہلے سے اکاؤنٹ ہے؟'),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRouter.login),
                        child: Text(_t('Sign In', 'لاگ ان کریں')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String selected;
  final bool isUrdu;
  final ValueChanged<String> onChanged;

  const _RoleSelector({
    required this.selected,
    required this.isUrdu,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = [
      (AppConstants.roleLandowner, isUrdu ? 'زمیندار' : 'Landowner', Icons.home_work_outlined),
      (AppConstants.roleManager,   isUrdu ? 'منیجر'   : 'Manager',   Icons.manage_accounts_outlined),
      (AppConstants.roleWorker,    isUrdu ? 'مزدور'   : 'Worker',    Icons.agriculture_outlined),
    ];

    return Row(
      children: roles.map((r) {
        final (value, label, icon) = r;
        final isSelected = selected == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}