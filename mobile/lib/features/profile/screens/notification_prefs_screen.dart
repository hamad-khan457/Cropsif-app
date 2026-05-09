import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/widgets/cropsify_app_bar.dart';
import '../../../data/models/notification_prefs_model.dart';
import '../../auth/widgets/auth_button.dart';

class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  State<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  NotificationPrefsModel _prefs = const NotificationPrefsModel();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prov = context.read<UserProvider>();
    await prov.loadNotificationPrefs();
    if (!mounted) return;
    final loaded = prov.prefs;
    if (loaded != null) {
      setState(() { _prefs = loaded; _initialized = true; });
    } else {
      setState(() => _initialized = true);
    }
  }

  Future<void> _save() async {
    final prov = context.read<UserProvider>();
    final ok = await prov.updateNotificationPrefs(_prefs);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(
              'Notification preferences saved',
              'اطلاعی ترجیحات محفوظ ہوئیں')),
          backgroundColor: AppTheme.primary,
        ),
      );
      context.go(AppRouter.profile);
    } else if (prov.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.error!), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final parts = isStart
        ? (_prefs.quietHoursStart?.split(':'))
        : (_prefs.quietHoursEnd?.split(':'));
    final init = parts != null
        ? TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]))
        : const TimeOfDay(hour: 22, minute: 0);

    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked == null || !mounted) return;
    final str =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _prefs = isStart
          ? _prefs.copyWith(quietHoursStart: str)
          : _prefs.copyWith(quietHoursEnd: str);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserProvider>();

    return Scaffold(
      appBar: CropsifyAppBar(
        titleEn: 'Notifications',
        titleUr: 'اطلاعات',
        onBack: () => context.go(AppRouter.profile),
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    context.tr('Alert Channels', 'الرٹ چینلز'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _Card(children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined,
                          color: AppTheme.primary),
                      title: Text(context.tr('Push Alerts', 'پش الرٹس'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(context.tr(
                          'Receive push notifications on your device',
                          'اپنے ڈیوائس پر پش نوٹیفیکیشنز وصول کریں')),
                      value: _prefs.pushAlerts,
                      activeColor: AppTheme.primary,
                      onChanged: (v) =>
                          setState(() => _prefs = _prefs.copyWith(pushAlerts: v)),
                    ),
                    const Divider(indent: 70, height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.email_outlined,
                          color: AppTheme.primary),
                      title: Text(context.tr('Email Digest', 'ای میل خلاصہ'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(context.tr(
                          'Daily summary sent to your email',
                          'آپ کی ای میل پر روزانہ خلاصہ بھیجا جاتا ہے')),
                      value: _prefs.emailDigest,
                      activeColor: AppTheme.primary,
                      onChanged: (v) =>
                          setState(() => _prefs = _prefs.copyWith(emailDigest: v)),
                    ),
                    const Divider(indent: 70, height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.sms_outlined,
                          color: AppTheme.primary),
                      title: Text(context.tr('SMS Alerts', 'ایس ایم ایس الرٹس'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(context.tr(
                          'Critical alerts via SMS',
                          'ایس ایم ایس کے ذریعے اہم الرٹس')),
                      value: _prefs.smsAlerts,
                      activeColor: AppTheme.primary,
                      onChanged: (v) =>
                          setState(() => _prefs = _prefs.copyWith(smsAlerts: v)),
                    ),
                  ]),

                  const SizedBox(height: 20),
                  Text(
                    context.tr('Quiet Hours', 'خاموشی کے اوقات'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                        'No alerts will be sent during quiet hours',
                        'خاموشی کے اوقات میں کوئی الرٹ نہیں بھیجا جائے گا'),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _Card(children: [
                    ListTile(
                      leading: const Icon(Icons.bedtime_outlined,
                          color: AppTheme.primary),
                      title: Text(context.tr('Start Time', 'شروع کا وقت'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text(
                        _prefs.quietHoursStart ??
                            context.tr('Not set', 'مقرر نہیں'),
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      onTap: () => _pickTime(true),
                    ),
                    const Divider(indent: 70, height: 1),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny_outlined,
                          color: AppTheme.primary),
                      title: Text(context.tr('End Time', 'ختم کا وقت'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text(
                        _prefs.quietHoursEnd ??
                            context.tr('Not set', 'مقرر نہیں'),
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      onTap: () => _pickTime(false),
                    ),
                    if (_prefs.quietHoursStart != null ||
                        _prefs.quietHoursEnd != null) ...[
                      const Divider(indent: 70, height: 1),
                      ListTile(
                        leading:
                            const Icon(Icons.clear, color: AppTheme.error),
                        title: Text(
                            context.tr('Clear quiet hours',
                                'خاموشی کے اوقات ختم کریں'),
                            style: const TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w600)),
                        onTap: () => setState(() =>
                            _prefs = _prefs.copyWith(clearQuietHours: true)),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 32),
                  AuthButton(
                    label: context.tr(
                        'Save Preferences', 'ترجیحات محفوظ کریں'),
                    loading: prov.loading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}
