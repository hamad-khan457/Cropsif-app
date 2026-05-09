import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/widgets/cropsify_app_bar.dart';
import '../widgets/profile_tile.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  Future<void> _exportData() async {
    final lang = context.read<LanguageProvider>();
    final prov = context.read<UserProvider>();
    final data = await prov.exportData();
    if (!mounted) return;
    if (data != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(lang.isUrdu ? 'برآمد کردہ ڈیٹا' : 'Exported Data'),
          content: SingleChildScrollView(
            child: Text(
              const JsonEncoder.withIndent('  ').convert(data),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.isUrdu ? 'بند کریں' : 'Close'),
            ),
          ],
        ),
      );
    } else if (prov.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.error!), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _deactivate() async {
    final lang = context.read<LanguageProvider>();
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.isUrdu ? 'اکاؤنٹ غیر فعال کریں' : 'Deactivate Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.isUrdu
                  ? 'یہ آپ کے اکاؤنٹ کو غیر فعال کر دے گا۔ آپ کو فوری طور پر سائن آؤٹ کر دیا جائے گا۔'
                  : 'This will deactivate your account. You will be signed out immediately.',
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: lang.isUrdu ? 'پاسورڈ کی تصدیق کریں' : 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.isUrdu ? 'منسوخ' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(lang.isUrdu ? 'غیر فعال کریں' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (passwordController.text.isEmpty) return;

    final prov = context.read<UserProvider>();
    final ok = await prov.deactivateAccount(passwordController.text);
    if (!mounted) return;
    passwordController.dispose();

    if (ok) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      context.go(AppRouter.welcome);
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
        titleEn: 'Account Settings',
        titleUr: 'اکاؤنٹ سیٹنگز',
        onBack: () => context.go(AppRouter.profile),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),

            // Data section
            Text(
              context.tr('Your Data', 'آپ کا ڈیٹا'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  fontSize: 12),
            ),
            const SizedBox(height: 8),
            _SectionCard(children: [
              ProfileTile(
                icon: Icons.download_outlined,
                title: context.tr('Export My Data', 'میرا ڈیٹا برآمد کریں'),
                subtitle: context.tr(
                    'Download a copy of your account data',
                    'اپنے اکاؤنٹ ڈیٹا کی کاپی ڈاؤن لوڈ کریں'),
                onTap: prov.loading ? null : _exportData,
                trailing: prov.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ]),

            const SizedBox(height: 24),

            // Danger zone
            Text(
              context.tr('Danger Zone', 'خطرناک زون'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.error,
                  fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  ProfileTile(
                    icon: Icons.person_off_outlined,
                    title: context.tr(
                        'Deactivate Account', 'اکاؤنٹ غیر فعال کریں'),
                    subtitle: context.tr(
                        'Your account will be deactivated and you\'ll be signed out',
                        'آپ کا اکاؤنٹ غیر فعال ہو جائے گا اور آپ کو سائن آؤٹ کر دیا جائے گا'),
                    destructive: true,
                    onTap: _deactivate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                context.tr('Cropsify v1.0.0 — Module 1',
                    'کروپسیفائی v1.0.0 — ماڈیول 1'),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}
