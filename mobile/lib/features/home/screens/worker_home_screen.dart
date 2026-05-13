import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';

// Task status enum
enum _TaskStatus { inProgress, pending, completed }

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  // Placeholder data — replace with real provider when backend supports it
  final String _parcelName     = 'North Field';
  final double _todayEarnings  = 850;
  final bool   _checkedIn      = true;
  final String _checkInTime    = '7:05 AM';
  final String _checkOutTime   = '';       // empty = not checked out yet
  final double _hoursWorked    = 5.2;

  final List<_TaskItem> _tasks = const [
    _TaskItem(
      icon: Icons.water_drop_outlined,
      iconColor: Color(0xFF1976D2),
      iconBg: Color(0xFFE3F2FD),
      titleEn: 'Irrigate',
      titleUr: 'آبپاشی کریں',
      block: 'Block A',
      status: _TaskStatus.inProgress,
    ),
    _TaskItem(
      icon: Icons.grass_outlined,
      iconColor: Color(0xFF388E3C),
      iconBg: Color(0xFFE8F5E9),
      titleEn: 'Fertilise',
      titleUr: 'کھاد ڈالیں',
      block: 'Block B',
      status: _TaskStatus.pending,
    ),
    _TaskItem(
      icon: Icons.agriculture_outlined,
      iconColor: Color(0xFFF9A825),
      iconBg: Color(0xFFFFFDE7),
      titleEn: 'Harvest',
      titleUr: 'فصل کاٹیں',
      block: 'Block C',
      status: _TaskStatus.completed,
    ),
  ];

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
          _WorkerHeader(
            user: user,
            parcelName: _parcelName,
            todayEarnings: _todayEarnings,
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
                        _AttendanceCard(
                          checkedIn:    _checkedIn,
                          checkInTime:  _checkInTime,
                          checkOutTime: _checkOutTime,
                          hoursWorked:  _hoursWorked,
                          isUrdu: isUrdu,
                        ),
                        const SizedBox(height: 22),
                        _SectionHeader(
                          en: "Today's Tasks",
                          ur: 'آج کے کام',
                          isUrdu: isUrdu,
                        ),
                        const SizedBox(height: 12),
                        ..._tasks.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TaskCard(task: t, isUrdu: isUrdu),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _UploadProofButton(isUrdu: isUrdu),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const _WorkerBottomNav(currentIndex: 0),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _WorkerHeader extends StatelessWidget {
  final UserModel? user;
  final String parcelName;
  final double todayEarnings;
  final bool isUrdu;

  const _WorkerHeader({
    this.user,
    required this.parcelName,
    required this.todayEarnings,
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
        right: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — name + location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'آج کا دن' : "Today",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                const SizedBox(height: 4),
                Text(
                  parcelName,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          // Right — today's earnings
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isUrdu ? 'آج کی اجرت' : "Today's Pay",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                'Rs. ${todayEarnings.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Attendance Card ────────────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final bool checkedIn;
  final String checkInTime;
  final String checkOutTime;
  final double hoursWorked;
  final bool isUrdu;

  const _AttendanceCard({
    required this.checkedIn,
    required this.checkInTime,
    required this.checkOutTime,
    required this.hoursWorked,
    required this.isUrdu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: checkedIn ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primary),
                ),
                child: checkedIn
                    ? const Icon(Icons.check, color: Colors.white, size: 15)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                isUrdu ? 'حاضری — Attendance' : 'Attendance — حاضری',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Three info columns
          Row(
            children: [
              Expanded(
                child: _AttendanceCell(
                  icon: Icons.arrow_downward,
                  iconColor: AppTheme.primary,
                  labelUr: 'آمد',
                  labelEn: 'Check-in',
                  value: checkInTime.isEmpty ? '--:--' : checkInTime,
                  isUrdu: isUrdu,
                ),
              ),
              Container(width: 1, height: 50, color: const Color(0xFFC8E6C9)),
              Expanded(
                child: _AttendanceCell(
                  icon: Icons.arrow_upward,
                  iconColor: const Color(0xFFFF8F00),
                  labelUr: 'روانگی',
                  labelEn: 'Check-out',
                  value: checkOutTime.isEmpty ? '--:--' : checkOutTime,
                  isUrdu: isUrdu,
                ),
              ),
              Container(width: 1, height: 50, color: const Color(0xFFC8E6C9)),
              Expanded(
                child: _AttendanceCell(
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFF7B1FA2),
                  labelUr: 'گھنٹے',
                  labelEn: 'Hours',
                  value: '${hoursWorked.toStringAsFixed(1)} hrs',
                  isUrdu: isUrdu,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Check Out button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                isUrdu ? 'چیک آؤٹ کریں — Check Out' : 'Check Out — چیک آؤٹ کریں',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String labelUr;
  final String labelEn;
  final String value;
  final bool isUrdu;

  const _AttendanceCell({
    required this.icon,
    required this.iconColor,
    required this.labelUr,
    required this.labelEn,
    required this.value,
    required this.isUrdu,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(
          isUrdu ? labelUr : labelEn,
          style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String en;
  final String ur;
  final bool isUrdu;
  const _SectionHeader({required this.en, required this.ur, required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    return Text(
      isUrdu ? '$ur — $en' : '$en — $ur',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}

// ── Task Card ──────────────────────────────────────────────────────────────────

class _TaskItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String titleEn;
  final String titleUr;
  final String block;
  final _TaskStatus status;
  const _TaskItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.titleEn,
    required this.titleUr,
    required this.block,
    required this.status,
  });
}

class _TaskCard extends StatelessWidget {
  final _TaskItem task;
  final bool isUrdu;
  const _TaskCard({required this.task, required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    final (badgeText, badgeBg, badgeFg) = switch (task.status) {
      _TaskStatus.inProgress => (
          isUrdu ? 'جاری' : 'In Progress',
          const Color(0xFFFFF8E1),
          const Color(0xFFFF8F00),
        ),
      _TaskStatus.pending => (
          isUrdu ? 'باقی' : 'Pending',
          const Color(0xFFECEFF1),
          const Color(0xFF607D8B),
        ),
      _TaskStatus.completed => (
          isUrdu ? 'مکمل' : 'Done',
          const Color(0xFFE8F5E9),
          AppTheme.primary,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: task.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(task.icon, color: task.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? '${task.titleUr} — ${task.titleEn}' : '${task.titleEn} — ${task.titleUr}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  task.block,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
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

// ── Upload Photo Proof ─────────────────────────────────────────────────────────

class _UploadProofButton extends StatelessWidget {
  final bool isUrdu;
  const _UploadProofButton({required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        side: const BorderSide(color: AppTheme.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.qr_code_scanner, size: 20),
      label: Text(
        isUrdu
            ? 'تصویر اپ لوڈ کریں — Upload Photo Proof'
            : 'Upload Photo Proof — تصویر اپ لوڈ کریں',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Bottom Navigation Bar ──────────────────────────────────────────────────────

class _WorkerBottomNav extends StatelessWidget {
  final int currentIndex;
  const _WorkerBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<LanguageProvider>().isUrdu;
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Earnings — coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
          case 3:
            context.go(AppRouter.profile);
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: isUrdu ? 'گھر' : 'Home',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment_outlined),
          activeIcon: const Icon(Icons.assignment),
          label: isUrdu ? 'کام' : 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.payments_outlined),
          activeIcon: const Icon(Icons.payments),
          label: isUrdu ? 'اجرت' : 'Earnings',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: isUrdu ? 'پروفائل' : 'Profile',
        ),
      ],
    );
  }
}
