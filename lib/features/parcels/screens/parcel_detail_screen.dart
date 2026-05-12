import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../providers/parcel_provider.dart';
import '../../../data/models/parcel_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';

class ParcelDetailScreen extends StatelessWidget {
  final ParcelModel parcel;
  const ParcelDetailScreen({super.key, required this.parcel});

  @override
  Widget build(BuildContext context) {
    final (badgeLabel, badgeColor) = switch (parcel.ndviBadge) {
      NdviBadge.healthy  => ('Healthy',  const Color(0xFF2E7D32)),
      NdviBadge.moderate => ('Moderate', const Color(0xFFF57F17)),
      NdviBadge.stressed => ('Stressed', const Color(0xFFD32F2F)),
      NdviBadge.unknown  => ('No Data',  const Color(0xFF757575)),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(parcel.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── Map preview ───────────────────────────────────────
          if (parcel.coordinates.isNotEmpty)
            SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _center(parcel.coordinates),
                  initialZoom:   14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cropsify.app',
                  ),
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points:            parcel.coordinates,
                        color:             AppTheme.primary.withOpacity(0.25),
                        borderColor:       AppTheme.primary,
                        borderStrokeWidth: 2.5,
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              height: 120,
              color: AppTheme.primary.withOpacity(0.06),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, color: AppTheme.textSecondary, size: 36),
                    SizedBox(height: 6),
                    Text('No GPS boundary recorded',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── NDVI & area row ───────────────────────────
                Row(
                  children: [
                    _Badge(badgeLabel, badgeColor),
                    const Spacer(),
                    if (parcel.areaAcres != null)
                      _StatPill(Icons.straighten,
                          '${parcel.areaAcres!.toStringAsFixed(2)} acres'),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Info card ─────────────────────────────────
                _InfoCard(children: [
                  if (parcel.location != null)
                    _Row(Icons.location_on_outlined, 'Location', parcel.location!),
                  if (parcel.activeCrop != null)
                    _Row(Icons.grass, 'Active Crop', parcel.activeCrop!),
                  if (parcel.soilType != null)
                    _Row(Icons.terrain_outlined, 'Soil Type', parcel.soilType!),
                  if (parcel.irrigation != null)
                    _Row(Icons.water_drop_outlined, 'Irrigation', parcel.irrigation!),
                  if (parcel.phLevel != null)
                    _Row(Icons.science_outlined, 'pH Level', '${parcel.phLevel}'),
                ]),
                const SizedBox(height: 16),

                // ── NPK card ──────────────────────────────────
                if (parcel.nitrogen != null || parcel.phosphorus != null || parcel.potassium != null) ...[
                  const Text('NPK Levels (kg/acre)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _NpkBox('N', parcel.nitrogen, const Color(0xFF1B5E20)),
                      const SizedBox(width: 12),
                      _NpkBox('P', parcel.phosphorus, const Color(0xFF0D47A1)),
                      const SizedBox(width: 12),
                      _NpkBox('K', parcel.potassium, const Color(0xFF4A148C)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Crop Plan CTA ─────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRouter.cropPlan, extra: parcel),
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('View AI Crop Plan'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Registered: ${_fmtDate(parcel.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LatLng _center(List<LatLng> pts) {
    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lng = pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lng);
  }

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Parcel'),
        content: Text('Remove "${parcel.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<ParcelProvider>().deleteParcel(parcel.id);
              if (context.mounted && ok) context.go(AppRouter.landPortfolio);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color  color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.satellite_alt_outlined, size: 13, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    ),
  );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _StatPill(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: AppTheme.textSecondary),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: children.expand((w) => [w, const Divider(height: 1, indent: 16)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    ),
  );
}

class _NpkBox extends StatelessWidget {
  final String  label;
  final double? value;
  final Color   color;
  const _NpkBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(value != null ? '${value!.toStringAsFixed(0)} kg' : '–',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    ),
  );
}
