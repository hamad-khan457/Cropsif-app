import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;
  final bool destructive;

  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.trailing,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.error : (iconColor ?? AppTheme.primary);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: destructive ? AppTheme.error : AppTheme.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))
          : null,
      trailing: trailing ?? (onTap != null
          ? const Icon(Icons.chevron_right, color: AppTheme.textSecondary)
          : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}