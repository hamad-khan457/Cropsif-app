import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/parcel_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/parcel_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<UserProvider>().loadProfile();
      if (!mounted) return;
      final user = context.read<UserProvider>().user;
      if (user?.role == 'manager') {
        context.replace(AppRouter.managerHome);
        return;
      }
      if (user?.role == 'worker') {
        context.replace(AppRouter.workerHome);
        return;
      }
      context.read<ParcelProvider>().loadParcels();
    });
  }

  String _greeting(bool isUrdu) {
    final h = DateTime.now().hour;
    if (h < 12) return isUrdu ? 'صبح بخیر 👋' : 'Good morning 👋';
    if (h < 17) return isUrdu ? 'دوپہر بخیر 👋' : 'Good afternoon 👋';
    return isUrdu ? 'شام بخیر 👋' : 'Good evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    final userProv   = context.watch<UserProvider>();
    final parcelProv = context.watch<ParcelProvider>();
    final lang       = context.watch<LanguageProvider>();
    final user       = userProv.user;
    final isUrdu     = lang.isUrdu;
    final parcels    = parcelProv.parcels;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _DashboardHeader(
            greeting: _greeting(isUrdu),
            user: user,
          ),
          Expanded(
            child: userProv.loading && user == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await context.read<UserProvider>().loadProfile();
                      await context.read<ParcelProvider>().loadParcels();
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _StatsGrid(parcels: parcels),
                        const SizedBox(height: 22),
                        Text(
                          isUrdu ? 'میرے کھیت' : 'My Parcels',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (parcelProv.loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (parcels.isEmpty)
                          _EmptyParcels(isUrdu: isUrdu)
                        else
                          ...parcels.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ParcelCard(parcel: p, isUrdu: isUrdu),
                              )),
                        const SizedBox(height: 4),
                        _RegisterParcelButton(isUrdu: isUrdu),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 0),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final UserModel? user;
  const _DashboardHeader({required this.greeting, this.user});

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
                  greeting,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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

class _StatsGrid extends StatelessWidget {
  final List<ParcelModel> parcels;
  const _StatsGrid({required this.parcels});

  @override
  Widget build(BuildContext context) {
    final activeManagers   = parcels.where((p) => p.managerName != null && p.managerName!.isNotEmpty).length;
    final pendingApprovals = 0;
    final activeAlerts     = 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: [
        _StatCard(
          value: '${parcels.length}',
          label: 'Parcels',
          labelUr: 'کھیت',
          valueColor: AppTheme.primary,
        ),
        _StatCard(
          value: '$activeManagers',
          label: 'Active Managers',
          labelUr: 'فعال منیجرز',
          valueColor: AppTheme.primary,
        ),
        _StatCard(
          value: '$pendingApprovals',
          label: 'Pending Approvals',
          labelUr: 'زیر التواء منظوریاں',
          valueColor: const Color(0xFFFF8F00),
        ),
        _StatCard(
          value: '$activeAlerts',
          label: 'Active Alerts',
          labelUr: 'فعال الرٹس',
          valueColor: const Color(0xFF1A1A1A),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String labelUr;
  final Color  valueColor;
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

// ── Parcel Card ────────────────────────────────────────────────────────────────

class _ParcelCard extends StatelessWidget {
  final ParcelModel parcel;
  final bool isUrdu;
  const _ParcelCard({required this.parcel, required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    final hasManager = parcel.managerName != null && parcel.managerName!.isNotEmpty;
    final isActive   = parcel.isActive && hasManager;

    final badgeText  = isActive
        ? (isUrdu ? 'فعال' : 'Active')
        : (isUrdu ? 'منیجر نہیں' : 'No Manager');
    final badgeBg    = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1);
    final badgeFg    = isActive ? AppTheme.primary : const Color(0xFFFF8F00);

    final details = [
      if (parcel.areaAcres != null)
        '${parcel.areaAcres!.toStringAsFixed(0)} ${isUrdu ? "ایکڑ" : "acres"}',
      if (parcel.activeCrop != null) parcel.activeCrop!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parcel.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 4),
                    Text(
                      hasManager
                          ? parcel.managerName!
                          : (isUrdu ? 'غیر مختص' : 'Unassigned'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyParcels extends StatelessWidget {
  final bool isUrdu;
  const _EmptyParcels({required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.terrain_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            isUrdu ? 'ابھی کوئی کھیت نہیں' : 'No parcels yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Register Parcel Button ─────────────────────────────────────────────────────

class _RegisterParcelButton extends StatelessWidget {
  final bool isUrdu;
  const _RegisterParcelButton({required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRouter.registerParcel),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: AppTheme.primary),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                isUrdu ? 'نئی زمین رجسٹر کریں' : 'Register New Parcel',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const radius = 12.0;
    const dash   = 6.0;
    const gap    = 4.0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(radius),
      ));

    final dest = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dash : gap;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, math.min(distance + len, metric.length)),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dest, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

// ── Bottom Navigation Bar ──────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

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
            context.go(AppRouter.landPortfolio);
          case 2:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Managers — coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
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
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Parcels',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Managers',
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
