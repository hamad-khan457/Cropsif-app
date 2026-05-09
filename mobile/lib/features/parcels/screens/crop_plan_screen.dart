import 'package:flutter/material.dart';
import '../../../data/models/parcel_model.dart';
import '../../../core/theme/app_theme.dart';

/// AI Crop Plan screen (Module 2 – FE-3)
/// Shows mock recommendations matching SRS Figure 5 design.
/// Will be replaced with live ML output when Module 3 AI pipeline is built.
class CropPlanScreen extends StatefulWidget {
  final ParcelModel parcel;
  const CropPlanScreen({super.key, required this.parcel});

  @override
  State<CropPlanScreen> createState() => _CropPlanScreenState();
}

class _CropPlanScreenState extends State<CropPlanScreen> {
  int _selected = 0;

  static const _crops = [
    _CropRec(
      name:       'Wheat (Sarsabz)',
      confidence: 91,
      profit:     186000,
      yieldMds:   42,
      days:       145,
      icon:       Icons.grain,
      color:      Color(0xFFF9A825),
    ),
    _CropRec(
      name:       'Maize (Hybrid)',
      confidence: 78,
      profit:     142000,
      yieldMds:   38,
      days:       120,
      icon:       Icons.eco,
      color:      Color(0xFF388E3C),
    ),
    _CropRec(
      name:       'Chickpea',
      confidence: 64,
      profit:     98000,
      yieldMds:   22,
      days:       105,
      icon:       Icons.spa_outlined,
      color:      Color(0xFF795548),
    ),
  ];

  static const _milestones = [
    ('Sowing',        'Nov 1–7  ·  18 kg seed/acre'),
    ('Irrigation 1',  'Nov 20   ·  Crown root initiation'),
    ('Fertilizer',    'Dec 5    ·  Urea top-dressing'),
    ('Irrigation 2',  'Jan 10   ·  Tillering stage'),
    ('Pest Check',    'Feb 1    ·  Yellow rust monitoring'),
    ('Harvest',       'Mar 20   ·  Combine harvesting'),
  ];

  @override
  Widget build(BuildContext context) {
    final crop = _crops[_selected];

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Crop Plan – ${widget.parcel.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── AI Notice ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.science_outlined, color: AppTheme.accent, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ML model integration coming in Module 3. '
                    'Recommendations below are illustrative based on SRS design.',
                    style: TextStyle(fontSize: 11, color: AppTheme.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Top recommendation ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('AI RECOMMENDATION',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10,
                                  fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('${crop.confidence}% confidence',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(crop.icon, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      crop.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on soil NPK, 5-year market data, and weather forecast '
                  'for ${widget.parcel.location ?? 'this parcel'}.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatBox('Rs ${(crop.profit / 1000).round()}K', 'Net Profit/acre'),
                    _StatBox('${crop.yieldMds} mds', 'Expected Yield'),
                    _StatBox('${crop.days} days', 'Season Length'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Other options ─────────────────────────────────────
          const Text('OTHER OPTIONS',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 10),

          ..._crops.asMap().entries.where((e) => e.key != 0).map((e) {
            final c   = e.value;
            final rank = e.key + 1;
            return GestureDetector(
              onTap: () => setState(() => _selected = e.key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _selected == e.key
                      ? AppTheme.primary.withOpacity(0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selected == e.key
                        ? AppTheme.primary
                        : const Color(0xFFE0E0E0),
                    width: _selected == e.key ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(c.icon, color: c.color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(
                            'Rs ${(c.profit / 1000).round()}K/acre  ·  '
                            '${c.yieldMds} mds  ·  ${c.days} days',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${rank}nd',
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // ── Seasonal plan preview ─────────────────────────────
          const Text('SEASONAL PLAN PREVIEW',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 12),

          ..._milestones.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: AppTheme.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(m.$2, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          )),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Full plan acceptance will be enabled when '
                      'the ML module is integrated (Module 3).'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Accept Plan & Generate Calendar'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Parcel'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    ),
  );
}

class _CropRec {
  final String   name;
  final int      confidence;
  final int      profit;
  final int      yieldMds;
  final int      days;
  final IconData icon;
  final Color    color;

  const _CropRec({
    required this.name, required this.confidence, required this.profit,
    required this.yieldMds, required this.days,
    required this.icon, required this.color,
  });
}
