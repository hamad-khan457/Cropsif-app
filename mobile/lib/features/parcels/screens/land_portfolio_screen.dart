import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/parcel_provider.dart';
import '../../../data/models/parcel_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';

class LandPortfolioScreen extends StatefulWidget {
  const LandPortfolioScreen({super.key});

  @override
  State<LandPortfolioScreen> createState() => _LandPortfolioScreenState();
}

class _LandPortfolioScreenState extends State<LandPortfolioScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParcelProvider>().loadParcels();
    });
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov     = context.watch<ParcelProvider>();
    final filtered = prov.parcels.where((p) =>
        p.name.toLowerCase().contains(_query.toLowerCase()) ||
        (p.location ?? '').toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Land Portfolio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.home),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.registerParcel),
        icon: const Icon(Icons.add),
        label: const Text('Register Parcel'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search parcels…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Stats row ────────────────────────────────────────────
          if (prov.parcels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${prov.parcels.length} parcel${prov.parcels.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· ${prov.parcels.fold(0.0, (s, p) => s + (p.areaAcres ?? 0)).toStringAsFixed(1)} acres total',
                    style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: prov.loading && prov.parcels.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _EmptyState(hasSearch: _query.isNotEmpty)
                    : RefreshIndicator(
                        onRefresh: () => context.read<ParcelProvider>().loadParcels(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _ParcelCard(
                            parcel: filtered[i],
                            onTap: () => context.push(
                              AppRouter.parcelDetail,
                              extra: filtered[i],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Parcel card ───────────────────────────────────────────────────────────────

class _ParcelCard extends StatelessWidget {
  final ParcelModel parcel;
  final VoidCallback onTap;

  const _ParcelCard({required this.parcel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final badge = parcel.ndviBadge;
    final (badgeLabel, badgeColor) = switch (badge) {
      NdviBadge.healthy  => ('Healthy',  const Color(0xFF2E7D32)),
      NdviBadge.moderate => ('Moderate', const Color(0xFFF57F17)),
      NdviBadge.stressed => ('Alert',    const Color(0xFFD32F2F)),
      NdviBadge.unknown  => ('No Data',  const Color(0xFF757575)),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      parcel.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (parcel.activeCrop != null)
                    _Chip(parcel.activeCrop!, AppTheme.primary),
                ],
              ),
              const SizedBox(height: 10),

              // Stats row
              Row(
                children: [
                  _Stat(Icons.straighten, '${parcel.areaAcres?.toStringAsFixed(1) ?? '–'} ac'),
                  const SizedBox(width: 16),
                  _Stat(Icons.terrain_outlined, parcel.soilType ?? '–'),
                  const SizedBox(width: 16),
                  _Stat(Icons.water_drop_outlined, parcel.irrigation ?? '–'),
                ],
              ),

              if (parcel.location != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(parcel.location!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // NDVI badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.satellite_alt_outlined,
                            size: 12, color: badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          parcel.ndviScore != null
                              ? 'NDVI ${parcel.ndviScore!.toStringAsFixed(2)}  ·  $badgeLabel'
                              : badgeLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeColor),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _Stat(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppTheme.textSecondary),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ],
  );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color  color;
  const _Chip(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(hasSearch ? Icons.search_off : Icons.landscape_outlined,
            size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text(
          hasSearch ? 'No parcels match your search'
                    : 'No parcels registered yet',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
        if (!hasSearch) ...[
          const SizedBox(height: 8),
          const Text(
            'Tap + to register your first farm parcel',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ],
    ),
  );
}
