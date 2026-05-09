import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../providers/parcel_provider.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cropsify_app_bar.dart';
import '../../../core/services/translation_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Step 0 — Details form    Step 1 — Draw map
// ══════════════════════════════════════════════════════════════════════════════
class RegisterParcelScreen extends StatefulWidget {
  const RegisterParcelScreen({super.key});
  @override
  State<RegisterParcelScreen> createState() => _RegisterParcelScreenState();
}

class _RegisterParcelScreenState extends State<RegisterParcelScreen> {
  int _step = 0;

  final _form         = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phCtrl       = TextEditingController();
  final _nCtrl        = TextEditingController();
  final _pCtrl        = TextEditingController();
  final _kCtrl        = TextEditingController();
  String? _soilType;
  String? _irrigation;
  List<LatLng> _verts = [];
  bool _translating = false;

  static const _soilTypes   = ['clay','sandy','loamy','clay-loam','sandy-loam','silt'];
  static const _irrigations = ['canal','tubewell','rainwater','drip','sprinkler','other'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _locationCtrl.dispose();
    _phCtrl.dispose(); _nCtrl.dispose(); _pCtrl.dispose(); _kCtrl.dispose();
    super.dispose();
  }

  double get _acres => _shoelaceAcres(_verts);

  Future<void> _save({bool skip = false}) async {
    // Only free-text fields are translated. Dropdowns/numbers stay as-is.
    String parcelName = _nameCtrl.text.trim();
    String? location  = _locationCtrl.text.trim().isEmpty
        ? null : _locationCtrl.text.trim();

    if (context.isUrdu) {
      setState(() => _translating = true);
      parcelName = await TranslationService.urduToEnglish(parcelName);
      if (location != null) {
        location = await TranslationService.urduToEnglish(location);
      }
      if (!mounted) return;
      setState(() => _translating = false);
    }

    final p = await context.read<ParcelProvider>().createParcel(
      name:        parcelName,
      location:    location,
      areaAcres:   _acres > 0 ? _acres : null,
      soilType:    _soilType, irrigation: _irrigation,
      phLevel:     double.tryParse(_phCtrl.text),
      nitrogen:    double.tryParse(_nCtrl.text),
      phosphorus:  double.tryParse(_pCtrl.text),
      potassium:   double.tryParse(_kCtrl.text),
      coordinates: skip ? [] : _verts,
    );
    if (!mounted) return;
    if (p != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr('Parcel registered!', 'پلاٹ رجسٹر ہو گیا!')),
        backgroundColor: AppTheme.primary));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.read<ParcelProvider>().error ?? 'Error'),
        backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ParcelProvider>().loading || _translating;
    return Scaffold(
      resizeToAvoidBottomInset: _step == 0,
      appBar: CropsifyAppBar(
        titleEn: _step == 0 ? 'Parcel Details'  : 'Draw Boundary',
        titleUr: _step == 0 ? 'پلاٹ کی تفصیل' : 'حدود بنائیں',
        onBack: () {
          if (_step == 1) setState(() => _step = 0);
          else context.pop();
        },
      ),
      body: _step == 0
          ? _buildForm()
          : _MapStep(
              key:      const ValueKey('map'),
              vertices: _verts,
              loading:  loading,
              acres:    _acres,
              onChange: (v) => setState(() => _verts = v),
              onSave:   () => _save(),
              onSkip:   () => _save(skip: true),
            ),
    );
  }

  Widget _buildForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Dot(1, true,  context.tr('Details',  'تفصیلات')),
            Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
            _Dot(2, false, context.tr('Draw Map', 'نقشہ بنائیں')),
          ]),
          const SizedBox(height: 24),

          _sec(context.tr('Basic Information', 'بنیادی معلومات')),
          _tf(_nameCtrl, context.tr('Parcel Name *', 'پلاٹ کا نام *'),
              hint: context.tr('e.g. Plot A', 'مثلاً پلاٹ الف'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.tr('Name required', 'نام ضروری ہے') : null),
          const SizedBox(height: 12),
          _tf(_locationCtrl, context.tr('Location / Village', 'مقام / گاؤں'),
              hint: context.tr('e.g. Chakwal, Punjab', 'مثلاً چکوال، پنجاب')),
          const SizedBox(height: 20),

          _sec(context.tr('Soil Information', 'مٹی کی معلومات')),
          _dd(context.tr('Soil Type', 'مٹی کی قسم'), _soilType, _soilTypes,
              (v) => setState(() => _soilType = v)),
          const SizedBox(height: 12),
          _tf(_phCtrl, context.tr('pH Level (optional)', 'پی ایچ سطح (اختیاری)'),
              hint: '6.8',
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 20),

          _sec(context.tr('NPK Levels (kg/acre)', 'NPK سطح (کلو/ایکڑ)')),
          Row(children: [
            Expanded(child: _tf(_nCtrl, context.tr('N', 'N نائٹروجن'), hint: '42', keyboard: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _tf(_pCtrl, context.tr('P', 'P فاسفورس'),  hint: '18', keyboard: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _tf(_kCtrl, context.tr('K', 'K پوٹاشیم'),  hint: '24', keyboard: TextInputType.number)),
          ]),
          const SizedBox(height: 20),

          _sec(context.tr('Irrigation Source', 'پانی کا ذریعہ')),
          _dd(context.tr('Irrigation', 'آبپاشی'), _irrigation, _irrigations,
              (v) => setState(() => _irrigation = v)),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_form.currentState!.validate()) setState(() => _step = 1);
              },
              icon:  const Icon(Icons.map_outlined),
              label: Text(context.tr('Next — Draw Boundary', 'آگے — حدود بنائیں')),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sec(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)));

  TextFormField _tf(TextEditingController c, String label, {
    String? hint, TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: c, keyboardType: keyboard, validator: validator,
    decoration: InputDecoration(labelText: label, hintText: hint));

  Widget _dd(String label, String? val, List<String> items, ValueChanged<String?> cb) =>
      DropdownButtonFormField<String>(
        value: val,
        hint: Text(label),
        decoration: InputDecoration(labelText: label),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: cb);
}

// ══════════════════════════════════════════════════════════════════════════════
// Map step
//
// Layout (Column, not Stack for the outer shell):
//   ┌─────────────────────────────────┐  ← search bar (always visible)
//   │  🔍  Search …          [Go]     │
//   │  Lahore  Islamabad  Karachi …   │
//   ├─────────────────────────────────┤
//   │                                 │
//   │          MAP  (Expanded)        │  ← tiles + polygon + markers
//   │                                 │     + location ○ button (FAB)
//   │                                 │     + hint badge
//   │  ──── bottom toolbar ────────── │  ← Positioned inside Stack
//   └─────────────────────────────────┘
//
// Drawing:
//   • Tap map  → place numbered dot
//   • 1-2 dots → just dots, no lines
//   • 3+ dots  → filled polygon
//   • Drag dot → move vertex (lines stretch automatically)
//   • Long-press dot → delete vertex
//   • Location ○ → fly to GPS position
// ══════════════════════════════════════════════════════════════════════════════
class _MapStep extends StatefulWidget {
  final List<LatLng> vertices;
  final bool         loading;
  final double       acres;
  final void Function(List<LatLng>) onChange;
  final VoidCallback onSave, onSkip;

  const _MapStep({
    super.key,
    required this.vertices,
    required this.loading,
    required this.acres,
    required this.onChange,
    required this.onSave,
    required this.onSkip,
  });

  @override
  State<_MapStep> createState() => _MapStepState();
}

class _MapStepState extends State<_MapStep> {
  final _mapCtrl    = MapController();
  final _searchCtrl = TextEditingController();
  late List<LatLng> _v;
  int?  _dragIdx;
  bool  _skipTap  = false;
  bool  _searching = false;
  bool  _locating  = false;

  static const _pk = LatLng(30.3753, 69.3451);

  static const _cities = [
    ('Lahore',     LatLng(31.5497, 74.3436)),
    ('Islamabad',  LatLng(33.7294, 73.0931)),
    ('Rawalpindi', LatLng(33.5651, 73.0169)),
    ('Faisalabad', LatLng(31.4504, 73.1350)),
    ('Multan',     LatLng(30.1575, 71.5249)),
    ('Peshawar',   LatLng(34.0151, 71.5805)),
    ('Karachi',    LatLng(24.8607, 67.0011)),
    ('Sialkot',    LatLng(32.4945, 74.5229)),
  ];

  @override
  void initState() {
    super.initState();
    _v = List.from(widget.vertices);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _push() => widget.onChange(List.from(_v));

  // ── Nominatim search ──────────────────────────────────────────────────────
  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent("$q Pakistan")}&format=json&limit=1');
      final res = await http.get(uri, headers: {'User-Agent': 'CropsifyApp/1.0'});
      if (!mounted) return;
      final data = jsonDecode(res.body) as List;
      if (data.isNotEmpty) {
        _mapCtrl.move(
          LatLng(double.parse(data[0]['lat'] as String),
                 double.parse(data[0]['lon'] as String)), 14);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('Location not found', 'مقام نہیں ملا'))));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr('Search failed', 'تلاش ناکام'))));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // ── GPS current location ──────────────────────────────────────────────────
  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr(
                'Location permission denied',
                'مقام کی اجازت نہیں دی گئی'))));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr(
              'Location permission permanently denied. Enable in settings.',
              'مقام کی اجازت مستقل طور پر مسترد۔ سیٹنگز میں فعال کریں۔'))));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 16);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr(
            'Could not get location', 'مقام حاصل نہیں ہو سکا'))));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ── Tap → add vertex ──────────────────────────────────────────────────────
  void _onTap(TapPosition _, LatLng ll) {
    if (_dragIdx != null || _skipTap) {
      _skipTap = false;
      return;
    }
    // Don't add a point too close to an existing one
    for (final v in _v) {
      final d = (ll.latitude - v.latitude) * (ll.latitude - v.latitude) +
                (ll.longitude - v.longitude) * (ll.longitude - v.longitude);
      if (d < 0.00009) return;
    }
    setState(() => _v.add(ll));
    _push();
  }

  // ── Drag vertex ───────────────────────────────────────────────────────────
  void _onDragStart(int i) => setState(() => _dragIdx = i);

  void _onDragUpdate(int i, DragUpdateDetails d) {
    if (_dragIdx != i) return;
    try {
      final cam  = _mapCtrl.camera;
      final cur  = cam.latLngToScreenPoint(_v[i]);
      final next = math.Point<double>(cur.x + d.delta.dx, cur.y + d.delta.dy);
      setState(() => _v[i] = cam.pointToLatLng(next));
    } catch (_) {}
  }

  void _onDragEnd(int i) {
    setState(() => _dragIdx = null);
    _skipTap = true;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _skipTap = false);
    });
    _push();
  }

  @override
  Widget build(BuildContext context) {
    final dragging = _dragIdx != null;
    final acres    = _shoelaceAcres(_v);

    final hint = _v.isEmpty
        ? context.tr('Tap the map to place a point',
                     'نقشے پر ٹیپ کریں — نقطہ رکھیں')
        : _v.length == 1
            ? context.tr('Add 2 more points to form a boundary',
                         '2 مزید نقطے لگائیں — حدود بنائیں')
            : _v.length == 2
                ? context.tr('Add 1 more point to close the shape',
                             '1 مزید نقطہ لگائیں — شکل بند کریں')
                : context.tr(
                    '${_v.length} pts · ${acres.toStringAsFixed(2)} ac · Drag dot to reshape',
                    '${_v.length} نقطے · ${acres.toStringAsFixed(2)} ایکڑ · گھسیٹ کر شکل بدلیں');

    return Column(
      children: [
        // ── SEARCH BAR (always visible at top, outside the map Stack) ─────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: context.tr(
                          'Search village or city…',
                          'گاؤں یا شہر تلاش کریں…'),
                      isDense: true,
                      prefixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2)))
                          : const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14)),
                    child: Text(context.tr('Go', 'جاؤ')),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _cities.map((c) {
                    final (name, loc) = c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => _mapCtrl.move(loc, 11),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(name,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── MAP + overlays ────────────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              // Map fills remaining area
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter:  _pk,
                    initialZoom:    5.5,
                    maxZoom:        19,
                    onTap:          _onTap,
                    backgroundColor: const Color(0xFFB8D8C8),
                    interactionOptions: InteractionOptions(
                      flags: dragging
                          ? InteractiveFlag.none
                          : InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cropsify.app',
                      maxZoom: 19,
                    ),

                    // Filled polygon (3+ vertices)
                    if (_v.length >= 3)
                      PolygonLayer(polygons: [
                        Polygon(
                          points: _v,
                          color: AppTheme.primary.withOpacity(0.18),
                          borderColor: AppTheme.primary,
                          borderStrokeWidth: 2.5,
                          isFilled: true,
                        ),
                      ]),

                    // Connecting line for exactly 2 vertices
                    if (_v.length == 2)
                      PolylineLayer(polylines: [
                        Polyline(
                            points: _v,
                            color: AppTheme.primary,
                            strokeWidth: 2.5),
                      ]),

                    // Numbered vertex dots
                    MarkerLayer(
                      markers: _v.asMap().entries.map((e) {
                        final i   = e.key;
                        final pos = e.value;
                        final draggingThis = _dragIdx == i;
                        return Marker(
                          point: pos, width: 44, height: 44,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart:  (_) => _onDragStart(i),
                            onPanUpdate: (d) => _onDragUpdate(i, d),
                            onPanEnd:    (_) => _onDragEnd(i),
                            onLongPress: () {
                              setState(() => _v.removeAt(i));
                              _push();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width:  draggingThis ? 44 : 34,
                              height: draggingThis ? 44 : 34,
                              decoration: BoxDecoration(
                                color: draggingThis
                                    ? const Color(0xFFFF6F00)
                                    : i == 0
                                        ? const Color(0xFF1B5E20)
                                        : AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                        draggingThis ? 0.4 : 0.25),
                                    blurRadius: draggingThis ? 12 : 5,
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // ── Current location button (small ○) ───────────────────────
              Positioned(
                right: 14,
                bottom: 145,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _locating ? null : _goToCurrentLocation,
                    child: SizedBox(
                      width: 44, height: 44,
                      child: Center(
                        child: _locating
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary))
                            : const Icon(Icons.my_location,
                                color: AppTheme.primary, size: 22),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Hint badge ───────────────────────────────────────────────
              Positioned(
                bottom: 138,
                left: 12, right: 68,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.60),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(hint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ),
                ),
              ),

              // ── Bottom toolbar ───────────────────────────────────────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Material(
                  elevation: 8,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          OutlinedButton.icon(
                            onPressed: _v.isEmpty
                                ? null
                                : () {
                                    setState(() => _v.removeLast());
                                    _push();
                                  },
                            icon: const Icon(Icons.undo, size: 17),
                            label: Text(context.tr('Undo', 'واپس')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: BorderSide(
                                  color: _v.isEmpty
                                      ? Colors.grey.shade300
                                      : AppTheme.error),
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _v.isEmpty
                                ? null
                                : () {
                                    setState(() => _v.clear());
                                    _push();
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: BorderSide(
                                  color: _v.isEmpty
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade400),
                              minimumSize: const Size(0, 44),
                            ),
                            child: Text(context.tr('Clear', 'صاف')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_v.length >= 3 && !widget.loading)
                                      ? widget.onSave
                                      : null,
                              icon: widget.loading
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(context.tr(
                                  'Save Parcel', 'پلاٹ محفوظ کریں')),
                              style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 44)),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: widget.onSkip,
                          child: Text(
                            context.tr(
                                'Skip — save without boundary',
                                'چھوڑیں — بغیر حدود محفوظ کریں'),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final int    num;
  final bool   active;
  final String label;
  const _Dot(this.num, this.active, this.label);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Center(child: Text('$num',
            style: TextStyle(
                color: active ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12))),
      ),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              fontSize: 10,
              color: active ? AppTheme.primary : AppTheme.textSecondary)),
    ],
  );
}

double _shoelaceAcres(List<LatLng> pts) {
  if (pts.length < 3) return 0;
  double area = 0;
  final n = pts.length;
  for (int i = 0; i < n; i++) {
    final j = (i + 1) % n;
    area += pts[i].longitude * pts[j].latitude;
    area -= pts[j].longitude * pts[i].latitude;
  }
  final sqDeg  = area.abs() / 2;
  final avgLat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / n;
  final cosLat = (avgLat * 0.01745329).abs().clamp(0.3, 1.0);
  return sqDeg * 111 * 111 * cosLat * 247.105;
}
