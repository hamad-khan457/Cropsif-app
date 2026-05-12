import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  // Placeholder stats — replace with real provider data when backend supports it
  final int _activeTasks     = 5;
  final int _workersToday    = 8;
  final int _overdueTasks    = 2;
  final int _unreadMessages  = 3;
  final String _parcelName   = 'North Field';
  final double _parcelAcres  = 12;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final lang     = context.watch<LanguageProvider>();
    final user     = userProv.user;
    final isUrdu   = lang.isUrdu;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _ManagerHeader(
            user: user,
            parcelName: _parcelName,
            parcelAcres: _parcelAcres,
            isUrdu: isUrdu,
          ),
          Expanded(
            child: userProv.loading && user == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await context.read<UserProvider>().loadProfile();
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _ManagerStatsGrid(
                          activeTasks:    _activeTasks,
                          workersToday:   _workersToday,
                          overdueTasks:   _overdueTasks,
                          unreadMessages: _unreadMessages,
                          isUrdu: isUrdu,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          isUrdu ? 'فوری اقدامات' : 'Quick Actions',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _QuickActionsPanel(
                          overdueTasks:   _overdueTasks,
                          unreadMessages: _unreadMessages,
                          workersToday:   _workersToday,
                          isUrdu: isUrdu,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const _ManagerBottomNav(currentIndex: 0),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _ManagerHeader extends StatelessWidget {
  final UserModel? user;
  final String parcelName;
  final double parcelAcres;
  final bool isUrdu;

  const _ManagerHeader({
    this.user,
    required this.parcelName,
    required this.parcelAcres,
    required this.isUrdu,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppTheme.primary,
      padding: EdgeInsets.only(
        top: top + 14,
        bottom: 18,
        left: 20,
        right: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'منیجر ویو' : 'Manager View',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFFFB300),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$parcelName · ${parcelAcres.toStringAsFixed(0)} ${isUrdu ? "ایکڑ" : "acres"}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFFFFB300),
              size: 28,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ── Stats Grid ─────────────────────────────────────────────────────────────────

class _ManagerStatsGrid extends StatelessWidget {
  final int activeTasks;
  final int workersToday;
  final int overdueTasks;
  final int unreadMessages;
  final bool isUrdu;

  const _ManagerStatsGrid({
    required this.activeTasks,
    required this.workersToday,
    required this.overdueTasks,
    required this.unreadMessages,
    required this.isUrdu,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: [
        _StatCard(
          value: '$activeTasks',
          label: 'Active Tasks',
          labelUr: 'فعال کام',
          valueColor: const Color(0xFFD32F2F),
        ),
        _StatCard(
          value: '$workersToday',
          label: 'Workers Today',
          labelUr: 'آج کے مزدور',
          valueColor: AppTheme.primary,
        ),
        _StatCard(
          value: '$overdueTasks',
          label: 'Overdue Tasks',
          labelUr: 'تاخیر سے کام',
          valueColor: const Color(0xFFFF8F00),
        ),
        _StatCard(
          value: '$unreadMessages',
          label: 'Unread Messages',
          labelUr: 'نہ پڑھے پیغامات',
          valueColor: const Color(0xFF7B1FA2),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String labelUr;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.labelUr,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<LanguageProvider>().isUrdu;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isUrdu ? labelUr : label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF757575),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────────

class _QuickActionsPanel extends StatelessWidget {
  final int overdueTasks;
  final int unreadMessages;
  final int workersToday;
  final bool isUrdu;

  const _QuickActionsPanel({
    required this.overdueTasks,
    required this.unreadMessages,
    required this.workersToday,
    required this.isUrdu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _ActionRow(
            iconBg: const Color(0xFFE8F5E9),
            icon: Icons.biotech_outlined,
            iconColor: AppTheme.primary,
            title: isUrdu ? 'بیماری اسکین' : 'Disease Scan',
            subtitle: isUrdu ? 'CNN سے پتہ اسکین کریں' : 'Scan a plant leaf with CNN',
            isFirst: true,
            onTap: () => context.push(AppRouter.plantDiseaseScan),
          ),
          _ActionRow(
            iconBg: const Color(0xFFFFF8E1),
            icon: Icons.person_add_outlined,
            iconColor: const Color(0xFFFF8F00),
            title: isUrdu ? 'مزدور بھرتی کریں' : 'Hire Worker',
            subtitle:
                isUrdu ? 'کھیت کے لیے نیا مزدور رجسٹر کریں' : 'Register new worker for parcel',
            onTap: () {},
          ),
          _ActionRow(
            iconBg: const Color(0xFFE3F2FD),
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF1976D2),
            title: isUrdu ? 'کام' : 'Tasks',
            subtitle: isUrdu
                ? '$overdueTasks تاخیر · 3 زیر التواء'
                : '$overdueTasks overdue · 3 pending',
            badge: overdueTasks,
            badgeColor: const Color(0xFFFF8F00),
            onTap: () {},
          ),
          _ActionRow(
            iconBg: const Color(0xFFF3E5F5),
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFF7B1FA2),
            title: isUrdu ? 'چیٹ' : 'Chat',
            subtitle: isUrdu ? '$unreadMessages نہ پڑھے پیغامات' : '$unreadMessages unread messages',
            badge: unreadMessages,
            badgeColor: const Color(0xFF7B1FA2),
            onTap: () {},
          ),
          _ActionRow(
            iconBg: const Color(0xFFE8F5E9),
            icon: Icons.how_to_reg_outlined,
            iconColor: AppTheme.primary,
            title: isUrdu ? 'حاضری' : 'Attendance',
            subtitle:
                isUrdu ? '$workersToday مزدور آج حاضر' : '$workersToday workers checked in today',
            isLast: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int? badge;
  final Color? badgeColor;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _ActionRow({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    this.isFirst = false,
    this.isLast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null && badge! > 0)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFBDBDBD),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 72, endIndent: 0, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}

// ── Bottom Navigation Bar ──────────────────────────────────────────────────────

class _ManagerBottomNav extends StatelessWidget {
  final int currentIndex;
  const _ManagerBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.accent,
      unselectedItemColor: const Color(0xFF9E9E9E),
      selectedFontSize: 11,
      unselectedFontSize: 11,
      backgroundColor: Colors.white,
      elevation: 8,
      onTap: (i) {
        if (i == currentIndex) return;
        switch (i) {
          case 1:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tasks — coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
          case 2:
            context.push(AppRouter.plantDiseaseScan);
          case 3:
            context.go(AppRouter.profile);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.biotech_outlined),
          activeIcon: Icon(Icons.biotech),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
