import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/widgets/cropsify_app_bar.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/translation_service.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../../auth/widgets/auth_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form     = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone    = TextEditingController();
  bool _translating = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _fullName.text = user.fullName;
      _phone.text    = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    String name  = _fullName.text.trim();
    String phone = _phone.text.trim();

    // Only the person's name is free-text — translate it to English before
    // saving so the database always stores English values.
    // Phone number is numeric; soil type / role / etc. are hardcoded English.
    if (context.isUrdu && name.isNotEmpty) {
      setState(() => _translating = true);
      name = await TranslationService.urduToEnglish(name);
      if (!mounted) return;
      setState(() => _translating = false);
    }

    final prov = context.read<UserProvider>();
    final ok = await prov.updateProfile(
      fullName: name,
      phone:    phone.isEmpty ? null : phone,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(
              'Profile updated successfully',
              'پروفائل کامیابی سے اپ ڈیٹ ہوئی')),
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
    final prov    = context.watch<UserProvider>();
    final loading = prov.loading || _translating;

    return Scaffold(
      appBar: CropsifyAppBar(
        titleEn: 'Edit Profile',
        titleUr: 'پروفائل تدوین کریں',
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
                      'Update your profile information',
                      'اپنی پروفائل معلومات اپ ڈیٹ کریں'),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  controller: _fullName,
                  label: context.tr('Full Name', 'پورا نام'),
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _phone,
                  label: context.tr(
                      'Phone Number (optional)', 'فون نمبر (اختیاری)'),
                  hint: '03001234567',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: Validators.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                ),
                if (_translating) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('Translating…', 'ترجمہ ہو رہا ہے…'),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ]),
                ],
                const SizedBox(height: 32),
                AuthButton(
                  label: context.tr('Save Changes', 'تبدیلیاں محفوظ کریں'),
                  loading: loading,
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
