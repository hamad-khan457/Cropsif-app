import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

    // Show toggle for all field-facing roles (landowner, manager, worker)
    // Admin sees English-only web panel so toggle not needed there
    final showLangToggle = user?.role != 'admin';

    return Directionality(
      textDirection: lang.isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Cropsify'),
          automaticallyImplyLeading: false,
          actions: [
            // Language toggle — shown for all non-admin roles
            if (showLangToggle)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: InkWell(
                  onTap: () => lang.toggle(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person_outline, color: Colors.white, size: 20),
              ),
              onPressed: () => context.go(AppRouter.profile),
            ),
          ],
        ),
        body: userProv.loading && user == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => context.read<UserProvider>().loadProfile(),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _GreetingCard(user: user),
                    const SizedBox(height: 24),
                    if (user != null) ..._quickActions(context, user.role, lang),
                    const SizedBox(height: 24),
                    _ComingSoonCard(),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _quickActions(BuildContext context, String role, LanguageProvider lang) {
    final actions = _actionsForRole(role, lang);
    return [
      Text(
        lang.t('Quick Actions', 'فوری اقدامات'),
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      ),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (_, i) => _ActionCard(
          icon:  actions[i].$1,
          label: actions[i].$2,
          color: actions[i].$3,
          onTap: actions[i].$4,
        ),
      ),
    ];
  }

  List<(IconData, String, Color, VoidCallback)> _actionsForRole(
      String role, LanguageProvider lang) {
    String t(String en, String ur) => lang.t(en, ur);

    return switch (role) {
      AppConstants.roleLandowner => [
        (Icons.map_outlined,        t('My Fields',  'میرے کھیت'),  const Color(0xFF388E3C), () => context.push(AppRouter.landPortfolio)),
        (Icons.people_outline,      t('My Team',    'میری ٹیم'),   const Color(0xFF1976D2), () {}),
        (Icons.bar_chart,           t('Financials', 'مالیات'),     const Color(0xFFFF8F00), () {}),
        (Icons.cloud_outlined,      t('Weather',    'موسم'),       const Color(0xFF0097A7), () {}),
      ],
      AppConstants.roleManager => [
        (Icons.checklist_outlined,  t('Tasks',        'کام'),             const Color(0xFF388E3C), () {}),
        (Icons.people_outline,      t('Workers',      'مزدور'),           const Color(0xFF1976D2), () {}),
        (Icons.terrain_outlined,    t('Fields',       'کھیت'),            const Color(0xFF7B1FA2), () => context.push(AppRouter.landPortfolio)),
        (Icons.bug_report_outlined, t('Pest Alerts',  'کیڑوں کی اطلاع'), const Color(0xFFD32F2F), () {}),
      ],
      AppConstants.roleWorker => [
        (Icons.task_alt_outlined,   t('My Tasks',     'میرے کام'),       const Color(0xFF388E3C), () {}),
        (Icons.location_on_outlined,t('Check In',     'حاضری'),          const Color(0xFF1976D2), () {}),
        (Icons.report_outlined,     t('Report Issue', 'مسئلہ رپورٹ'),    const Color(0xFFFF8F00), () {}),
        (Icons.cloud_outlined,      t('Weather',      'موسم'),           const Color(0xFF0097A7), () {}),
      ],
      _ => [
        (Icons.people_outline, 'Users',   const Color(0xFF388E3C), () {}),
        (Icons.bar_chart,      'Reports', const Color(0xFF1976D2), () {}),
      ],
    };
  }
}

// ── Greeting card ─────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  final UserModel? user;
  const _GreetingCard({this.user});

  String _greeting(bool isUrdu) {
    final h = DateTime.now().hour;
    if (h < 12) return isUrdu ? 'صبح بخیر،'    : 'Good morning,';
    if (h < 17) return isUrdu ? 'دوپہر بخیر،'  : 'Good afternoon,';
    return             isUrdu ? 'شام بخیر،'     : 'Good evening,';
  }

  String _roleLabel(UserModel u, bool isUrdu) {
    if (!isUrdu) return u.roleLabel;
    return switch (u.role) {
      'landowner' => 'زمیندار',
      'manager'   => 'فارم منیجر',
      'worker'    => 'فیلڈ ورکر',
      'admin'     => 'منتظم',
      _           => u.roleLabel,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<LanguageProvider>().isUrdu;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(isUrdu),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.fullName.split(' ').first ?? (isUrdu ? 'کسان' : 'Farmer'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user != null ? _roleLabel(user!, isUrdu) : '',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.grass, size: 36, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ── Action card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coming soon card ──────────────────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<LanguageProvider>().isUrdu;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_outlined, color: AppTheme.primary, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'مزید خصوصیات آ رہی ہیں' : 'More Features Coming',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  isUrdu
                      ? 'سیٹلائٹ نگرانی، AI معاون، بیماری کی تشخیص اور مزید — جلد آ رہا ہے۔'
                      : 'Satellite monitoring, AI assistant, disease detection & more — coming soon.',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
