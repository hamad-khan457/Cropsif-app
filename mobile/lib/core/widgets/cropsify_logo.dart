import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CropsifyLogo extends StatelessWidget {
  final double size;
  final bool onDark;

  const CropsifyLogo({super.key, this.size = 100, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final fg  = onDark ? Colors.white         : AppTheme.primary;
    final fg2 = onDark ? Colors.white70       : AppTheme.primaryLight;
    final bg  = onDark
        ? Colors.white.withOpacity(0.15)
        : AppTheme.primary.withOpacity(0.08);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Icon badge ─────────────────────────────────────────
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: fg.withOpacity(0.30), width: 2),
            boxShadow: onDark
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Hand (lower half)
              Positioned(
                bottom: size * 0.14,
                child: Icon(Icons.back_hand_outlined,
                    size: size * 0.46, color: fg2),
              ),
              // Plant (upper half, overlaps hand)
              Positioned(
                top: size * 0.08,
                child: Icon(Icons.eco_rounded,
                    size: size * 0.42, color: fg),
              ),
            ],
          ),
        ),

        SizedBox(height: size * 0.13),

        // ── App name ───────────────────────────────────────────
        Text(
          'Cropsify',
          style: TextStyle(
            color: fg,
            fontSize: size * 0.28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),

        SizedBox(height: size * 0.03),

        // ── Tagline ────────────────────────────────────────────
        Text(
          'Intelligent Farm Management',
          style: TextStyle(
            color: onDark ? Colors.white60 : AppTheme.textSecondary,
            fontSize: size * 0.105,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}