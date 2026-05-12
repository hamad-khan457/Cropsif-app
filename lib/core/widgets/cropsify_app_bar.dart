import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../theme/app_theme.dart';

/// AppBar used across every screen — always includes the EN / اردو toggle.
class CropsifyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleEn;
  final String titleUr;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBack;
  final List<Widget> extraActions;

  const CropsifyAppBar({
    super.key,
    required this.titleEn,
    String? titleUr,
    this.automaticallyImplyLeading = true,
    this.onBack,
    this.extraActions = const [],
  }) : titleUr = titleUr ?? titleEn;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AppBar(
      title: Text(lang.isUrdu ? titleUr : titleEn),
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            )
          : null,
      actions: [
        // Language toggle — always visible
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: InkWell(
            onTap: () => lang.toggle(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: Colors.white54),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    lang.isUrdu ? 'EN' : 'اردو',
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ...extraActions,
      ],
    );
  }
}
