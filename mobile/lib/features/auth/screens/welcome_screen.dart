import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/language_provider.dart';
import '../../../router/app_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFEDF7ED),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _AppIconBadge(),
              const SizedBox(height: 24),
              const Text(
                'Cropsify',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'Intelligent Farm Management\nfor Pakistan\'s landowners',
                  'پاکستان کے زمینداروں کے لیے\nذہین فارم مینجمنٹ',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => context.go(AppRouter.register),
                child: Text(context.tr('Get Started', 'شروع کریں')),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  backgroundColor: const Color(0xFFE8F5E9),
                  side: const BorderSide(color: AppTheme.primary, width: 1.5),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => context.go(AppRouter.login),
                child: Text(context.tr('Sign In', 'لاگ ان')),
              ),
              const SizedBox(height: 36),
              const _RoleRow(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppIconBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 18,
            child: Icon(Icons.back_hand_outlined,
                size: 42, color: AppTheme.primaryLight),
          ),
          Positioned(
            top: 12,
            child: Icon(Icons.eco_rounded, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _RoleItem(emoji: '🏡', label: 'Landowner'),
        SizedBox(width: 28),
        _RoleItem(emoji: '👨‍💼', label: 'Manager'),
        SizedBox(width: 28),
        _RoleItem(emoji: '🌱', label: 'Worker'),
      ],
    );
  }
}

class _RoleItem extends StatelessWidget {
  final String emoji;
  final String label;
  const _RoleItem({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
