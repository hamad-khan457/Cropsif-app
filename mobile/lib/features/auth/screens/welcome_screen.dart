import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cropsify_logo.dart';
import '../../../providers/language_provider.dart';
import '../../../router/app_router.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // Language toggle top-right
            Positioned(
              top: 12, right: 16,
              child: _LangToggle(lang: lang),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const CropsifyLogo(size: 130, onDark: true),
                  const SizedBox(height: 16),
                  Text(
                    context.tr(
                      'Manage your farms intelligently\nfrom anywhere in Pakistan',
                      'پاکستان میں کہیں سے بھی\nاپنے فارم ذہانت سے منظم کریں',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const Spacer(flex: 3),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => context.go(AppRouter.register),
                    child: Text(context.tr('Get Started', 'شروع کریں')),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => context.go(AppRouter.login),
                    child: Text(context.tr('Sign In', 'لاگ ان')),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final LanguageProvider lang;
  const _LangToggle({required this.lang});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => lang.toggle(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white54),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            lang.isUrdu ? 'EN' : 'اردو',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
