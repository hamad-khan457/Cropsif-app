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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadProfile();
    });
  }

  Future<void> _logout() async {
    final lang = context.read<LanguageProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.isUrdu ? 'سائن آؤٹ' : 'Sign Out'),
        content: Text(lang.isUrdu
            ? 'کیا آپ واقعی سائن آؤٹ کرنا چاہتے ہیں؟'
            : 'Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.isUrdu ? 'منسوخ' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(lang.isUrdu ? 'سائن آؤٹ' : 'Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    context.go(AppRouter.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final user     = userProv.user;
    final isUrdu   = context.isUrdu;

    return Scaffold(
      appBar: CropsifyAppBar(
        titleEn: 'Profile',
        titleUr: 'پروفائل',
        onBack: () => context.go(AppRouter.home),
      ),
      body: userProv.loading && user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  color: AppTheme.primary,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white24,
                        child: Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? '—',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '—',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user?.localizedRoleLabel(isUrdu) ?? '',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Account Section ──────────────────────────────────────────
                _SectionCard(children: [
                  ProfileTile(
                    icon: Icons.person_outline,
                    title: context.tr('Edit Profile', 'پروفائل تدوین کریں'),
                    subtitle: context.tr(
                        'Update name and phone number',
                        'نام اور فون نمبر تبدیل کریں'),
                    onTap: () => context.go(AppRouter.editProfile),
                  ),
                  const Divider(indent: 70, height: 1),
                  ProfileTile(
                    icon: Icons.lock_outline,
                    title: context.tr('Change Password', 'پاسورڈ تبدیل کریں'),
                    subtitle: context.tr(
                        'Update your password', 'اپنا پاسورڈ اپ ڈیٹ کریں'),
                    onTap: () => context.go(AppRouter.changePassword),
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Preferences Section ──────────────────────────────────────
                _SectionCard(children: [
                  ProfileTile(
                    icon: Icons.notifications_outlined,
                    title: context.tr('Notifications', 'اطلاعات'),
                    subtitle: context.tr(
                        'Manage alerts and preferences',
                        'الرٹس اور ترجیحات'),
                    onTap: () => context.go(AppRouter.notifications),
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Account Info ─────────────────────────────────────────────
                _SectionCard(children: [
                  ProfileTile(
                    icon: Icons.badge_outlined,
                    title: context.tr('CNIC', 'قومی شناختی کارڈ'),
                    subtitle: user?.cnic ??
                        context.tr('Not provided', 'فراہم نہیں کیا گیا'),
                  ),
                  const Divider(indent: 70, height: 1),
                  ProfileTile(
                    icon: Icons.phone_outlined,
                    title: context.tr('Phone', 'فون'),
                    subtitle: user?.phone ??
                        context.tr('Not provided', 'فراہم نہیں کیا گیا'),
                  ),
                  const Divider(indent: 70, height: 1),
                  ProfileTile(
                    icon: Icons.verified_user_outlined,
                    title: context.tr('Account Status', 'اکاؤنٹ کی حیثیت'),
                    subtitle: user?.isVerified == true
                        ? context.tr('Verified', 'تصدیق شدہ')
                        : context.tr('Not verified', 'غیر تصدیق شدہ'),
                    iconColor: user?.isVerified == true
                        ? Colors.green
                        : Colors.orange,
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Settings + Logout ────────────────────────────────────────
                _SectionCard(children: [
                  ProfileTile(
                    icon: Icons.settings_outlined,
                    title: context.tr('Account Settings', 'اکاؤنٹ سیٹنگز'),
                    subtitle: context.tr(
                        'Deactivate account, export data',
                        'اکاؤنٹ غیر فعال کریں، ڈیٹا برآمد کریں'),
                    onTap: () => context.go(AppRouter.accountSettings),
                  ),
                  const Divider(indent: 70, height: 1),
                  ProfileTile(
                    icon: Icons.logout,
                    title: context.tr('Sign Out', 'سائن آؤٹ'),
                    destructive: true,
                    onTap: _logout,
                  ),
                ]),

                const SizedBox(height: 32),
              ],
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
