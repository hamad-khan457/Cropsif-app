import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../../../providers/parcel_provider.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cropsify_app_bar.dart';
import '../../../core/services/translation_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Parent screen — owns both steps
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

  String?          _soilType;
  String?          _irrigation;
  List<ll.LatLng>  _verts       = [];
  bool             _translating = false;

  static const _soilTypes   = ['clay', 'sandy', 'loamy', 'clay-loam', 'sandy-loam', 'silt'];
  static const _irrigations = ['canal', 'tubewell', 'rainwater', 'drip', 'sprinkler', 'other'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _locationCtrl.dispose();
    _phCtrl.dispose(); _nCtrl.dispose(); _pCtrl.dispose(); _kCtrl.dispose();
    super.dispose();
  }

  double get _acres => _shoelaceAcres(_verts);

  Future<void> _save({bool skip = false}) async {
    String  parcelName = _nameCtrl.text.trim();
    String? location   = _locationCtrl.text.trim().isEmpty
        ? null : _locationCtrl.text.trim();

    if (context.isUrdu) {
      setState(() => _translating = true);
      parcelName = await TranslationService.urduToEnglish(parcelName);
      if (location != null) location = await TranslationService.urduToEnglish(location);
      if (!mounted) return;
      setState(() => _translating = false);
    }

    final p = await context.read<ParcelProvider>().createParcel(
      name:        parcelName,
      location:    location,
      areaAcres:   _acres > 0 ? _acres : null,
      soilType:    _soilType,
      irrigation:  _irrigation,
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
        backgroundColor: AppTheme.primary,
      ));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.read<ParcelProvider>().error ?? 'Error'),
        backgroundColor: AppTheme.error,
      ));
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
          if (_step == 1) {
            setState(() => _step = 0);
          } else {
            context.pop();
          }
        },
      ),
      body: _step == 0
          ? _buildForm()
          : _MapStep(
              key:      const ValueKey('map'),
              vertices: _verts,
              loading:  loading,
              onChange: (v) => setState(() => _verts = v),
              onSave:   () => _save(),
              onSkip:   () => _save(skip: true),
            ),
    );
  }

  // ── Step 1: details form ────────────────────────────────────────────────────

  Widget _buildForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Row(children: [
            _StepDot(1, true,  context.tr('Details',  'تفصیلات')),
            Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
            _StepDot(2, false, context.tr('Draw Map', 'نقشہ بنائیں')),
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
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
  );

  TextFormField _tf(TextEditingController c, String label, {
    String? hint,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: c, keyboardType: keyboard, validator: validator,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );

  Widget _dd(String label, String? val, List<String> items, ValueChanged<String?> cb) =>
      DropdownButtonFormField<String>(
        value: val, hint: Text(label),
        decoration: InputDecoration(labelText: label),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: cb,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Draw mode
// ══════════════════════════════════════════════════════════════════════════════

enum _DrawMode { place, connect }

// ══════════════════════════════════════════════════════════════════════════════
// Step 2 — flutter_map + OpenStreetMap polygon drawing
// ══════════════════════════════════════════════════════════════════════════════

class _MapStep extends StatefulWidget {
  final List<ll.LatLng>                vertices;
  final bool                           loading;
  final void Function(List<ll.LatLng>) onChange;
  final VoidCallback                   onSave;
  final VoidCallback                   onSkip;

  const _MapStep({
    super.key,
    required this.vertices,
    required this.loading,
    required this.onChange,
    required this.onSave,
    required this.onSkip,
  });

  @override
  State<_MapStep> createState() => _MapStepState();
}

class _MapStepState extends State<_MapStep> {
  // MapController — do NOT call dispose() on it (flutter_map manages lifecycle)
  final MapController _mapCtrl = MapController();
  final _searchCtrl = TextEditingController();

  List<ll.LatLng> _dots  = [];
  List<List<int>> _edges = [];
  _DrawMode _mode        = _DrawMode.place;
  int?      _connectFrom;
  int?      _draggingIdx;

  bool _searching = false;
  bool _locating  = false;

  static const _initialCenter = ll.LatLng(30.3753, 69.3451);
  static const _initialZoom   = 5.5;

  static const _cities = [
    ('Lahore',     ll.LatLng(31.5497, 74.3436)),
    ('Islamabad',  ll.LatLng(33.7294, 73.0931)),
    ('Rawalpindi', ll.LatLng(33.5651, 73.0169)),
    ('Faisalabad', ll.LatLng(31.4504, 73.1350)),
    ('Multan',     ll.LatLng(30.1575, 71.5249)),
    ('Peshawar',   ll.LatLng(34.0151, 71.5805)),
    ('Karachi',    ll.LatLng(24.8607, 67.0011)),
    ('Sialkot',    ll.LatLng(32.4945, 74.5229)),
  ];

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _dots = List.from(widget.vertices);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    // Do NOT call _mapCtrl.dispose() — flutter_map v6+ has no such method
    super.dispose();
  }

  // ── Drawing logic ───────────────────────────────────────────────────────────

  void _push() => widget.onChange(List.from(_dots));

  bool get _isClosed {
    if (_dots.length < 3 || _edges.length < _dots.length) return false;
    final deg = List.filled(_dots.length, 0);
    for (final e in _edges) { deg[e[0]]++; deg[e[1]]++; }
    return deg.every((d) => d >= 2);
  }

  double get _acres => _isClosed ? _shoelaceAcres(_ring) : 0;

  List<ll.LatLng> get _ring {
    try {
      if (!_isClosed) return [];
      final adj = List.generate(_dots.length, (_) => <int>[]);
      for (final e in _edges) { adj[e[0]].add(e[1]); adj[e[1]].add(e[0]); }
      final out = <int>[];
      var cur = 0; int? prev;
      while (out.length < _dots.length) {
        out.add(cur);
        final next = adj[cur].firstWhere(
            (n) => n != prev && !out.contains(n), orElse: () => -1);
        if (next == -1) break;
        prev = cur; cur = next;
      }
      return out.map((i) => _dots[i]).toList();
    } catch (_) { return []; }
  }

  void _onMapTap(ll.LatLng pos) {
    if (_mode != _DrawMode.place || _draggingIdx != null) return;
    setState(() => _dots.add(pos));
    _push();
  }

  void _onDotTap(int idx) {
    if (_mode != _DrawMode.connect) return;
    setState(() {
      if (_connectFrom == null) {
        _connectFrom = idx;
      } else if (_connectFrom != idx) {
        final a = _connectFrom!, b = idx;
        final exists = _edges.any(
            (e) => (e[0] == a && e[1] == b) || (e[0] == b && e[1] == a));
        if (!exists) { _edges.add([a, b]); _push(); }
        _connectFrom = b;
      } else {
        _connectFrom = null;
      }
    });
  }

  void _deleteDot(int idx) {
    setState(() {
      _edges.removeWhere((e) => e[0] == idx || e[1] == idx);
      _edges = _edges.map((e) => [
        e[0] > idx ? e[0] - 1 : e[0],
        e[1] > idx ? e[1] - 1 : e[1],
      ]).toList();
      _dots.removeAt(idx);
      if (_connectFrom == idx) {
        _connectFrom = null;
      } else if (_connectFrom != null && _connectFrom! > idx) {
        _connectFrom = _connectFrom! - 1;
      }
    });
    _push();
  }

  void _autoConnect() {
    if (_dots.length < 3) return;
    setState(() {
      _edges = [for (int i = 0; i < _dots.length; i++) [i, (i + 1) % _dots.length]];
      _connectFrom = null;
    });
    _push();
  }

  void _undo() {
    setState(() {
      if (_mode == _DrawMode.connect && _edges.isNotEmpty) {
        _edges.removeLast(); _connectFrom = null;
      } else if (_mode == _DrawMode.place && _dots.isNotEmpty) {
        final last = _dots.length - 1;
        _edges.removeWhere((e) => e[0] == last || e[1] == last);
        _dots.removeLast();
      }
    });
    _push();
  }

  void _clear() {
    setState(() { _dots.clear(); _edges.clear(); _connectFrom = null; });
    _push();
  }

  // ── Marker drag helpers ─────────────────────────────────────────────────────

  void _onDotPanStart(int idx) => setState(() => _draggingIdx = idx);

  void _onDotPanUpdate(int idx, DragUpdateDetails d) {
    if (_draggingIdx != idx) return;
    // project() returns global Mercator pixels at current zoom.
    // Screen pixels and global pixels differ only by a translation (pixelOrigin),
    // so a screen delta equals a global pixel delta — adding it directly is correct.
    final cam = _mapCtrl.camera;
    final pt  = cam.project(_dots[idx]);
    final np  = math.Point<double>(pt.x + d.delta.dx, pt.y + d.delta.dy);
    setState(() => _dots[idx] = cam.unproject(np));
  }

  void _onDotPanEnd(int idx) {
    setState(() => _draggingIdx = null);
    _push();
  }

  // ── Search & GPS ─────────────────────────────────────────────────────────────

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
        final lat = double.parse(data[0]['lat'] as String);
        final lon = double.parse(data[0]['lon'] as String);
        _mapCtrl.move(ll.LatLng(lat, lon), 14);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(context.tr('Location not found', 'مقام نہیں ملا'))));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr('Search failed', 'تلاش ناکام'))));
      }
    } finally {
      if (mounted) { setState(() => _searching = false); }
    }
  }

  Future<void> _gotoMyLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
          if (perm == LocationPermission.denied) { return; }
      }
      if (perm == LocationPermission.deniedForever) { return; }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) { _mapCtrl.move(ll.LatLng(pos.latitude, pos.longitude), 16); }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr('Could not get location', 'مقام حاصل نہیں ہو سکا'))));
      }
    } finally {
      if (mounted) { setState(() => _locating = false); }
    }
  }

  // ── Hint ────────────────────────────────────────────────────────────────────

  String get _hint {
    if (_dots.isEmpty)      return context.tr('Tap map to place dot 1', 'ٹیپ کریں — پہلا نقطہ لگائیں');
    if (_dots.length == 1)  return context.tr('Add 2 more dots', '2 مزید نقطے لگائیں');
    if (_dots.length == 2)  return context.tr('Add 1 more dot, then switch to Connect', '1 مزید نقطہ، پھر Connect موڈ');
    if (_mode == _DrawMode.place) return context.tr('${_dots.length} dots — switch to Connect to draw edges', '${_dots.length} نقطے — Connect موڈ میں جائیں');
    if (_isClosed)          return context.tr('Boundary closed · ${_acres.toStringAsFixed(2)} acres', 'حدود مکمل · ${_acres.toStringAsFixed(2)} ایکڑ');
    if (_connectFrom == null) return context.tr('Tap a dot to start connecting', 'نقطہ ٹیپ کریں');
    return context.tr('Dot ${_connectFrom! + 1} selected — tap another dot', 'نقطہ ${_connectFrom! + 1} — دوسرا ٹیپ کریں');
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final closed  = _isClosed;
    final canUndo = _dots.isNotEmpty || _edges.isNotEmpty;
    final isDragging = _draggingIdx != null;

    // ── flutter_map layers ──────────────────────────────────────────────────
    final polylines = _edges.map((e) => Polyline(
      points: [_dots[e[0]], _dots[e[1]]],
      color: (_connectFrom != null &&
              (e[0] == _connectFrom || e[1] == _connectFrom))
          ? const Color(0xFFFF6F00)
          : AppTheme.primary,
      strokeWidth: 3,
    )).toList();

    final ring = _ring;
    final polygons = ring.length >= 3
        ? [Polygon(
            points: ring,
            color: AppTheme.primary.withOpacity(0.18),
            borderColor: AppTheme.primary,
            borderStrokeWidth: 3,
          )]
        : <Polygon>[];

    final markers = List.generate(_dots.length, (i) => Marker(
      point:  _dots[i],
      width:  36,
      height: 36,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:        () => _onDotTap(i),
        onLongPress:  () => _deleteDot(i),
        onPanStart:   (_) => _onDotPanStart(i),
        onPanUpdate:  (d) => _onDotPanUpdate(i, d),
        onPanEnd:     (_) => _onDotPanEnd(i),
        child: _DotWidget(
          n:          i + 1,
          isFirst:    i == 0,
          isSelected: _connectFrom == i,
        ),
      ),
    ));

    return Column(
      children: [

        // ── Search bar ──────────────────────────────────────────────────────
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
                      hintText: context.tr('Search village or city…', 'گاؤں یا شہر تلاش کریں…'),
                      isDense: true,
                      prefixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2)))
                          : const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:  BorderSide(color: Colors.grey.shade300)),
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
              // City quick-jump chips
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
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

        // ── Map + overlays ──────────────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [

              // SizedBox.expand is the required parent for FlutterMap (not Positioned.fill)
              SizedBox.expand(
                child: FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom:   _initialZoom,
                    interactionOptions: InteractionOptions(
                      // Disable map panning while dragging a dot
                      flags: isDragging ? InteractiveFlag.none : InteractiveFlag.all,
                    ),
                    onTap: (_, point) => _onMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cropsify.app',
                    ),
                    if (polylines.isNotEmpty)
                      PolylineLayer(polylines: polylines),
                    if (polygons.isNotEmpty)
                      PolygonLayer(polygons: polygons),
                    if (markers.isNotEmpty)
                      MarkerLayer(markers: markers),
                  ],
                ),
              ),

              // ── Place / Connect mode toggle ─────────────────────────────
              Positioned(
                top: 12, left: 12,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _mode = _mode == _DrawMode.place
                        ? _DrawMode.connect
                        : _DrawMode.place;
                    _connectFrom = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: _mode == _DrawMode.place ? Colors.white : AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        _mode == _DrawMode.place
                            ? Icons.add_location_alt_outlined
                            : Icons.polyline_outlined,
                        size: 15,
                        color: _mode == _DrawMode.place ? AppTheme.primary : Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _mode == _DrawMode.place
                            ? context.tr('Place dots', 'نقطے لگائیں')
                            : context.tr('Connect dots', 'نقطے ملائیں'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _mode == _DrawMode.place ? AppTheme.primary : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.swap_horiz,
                          size: 13,
                          color: _mode == _DrawMode.place
                              ? Colors.grey.shade500
                              : Colors.white70),
                    ]),
                  ),
                ),
              ),

              // ── Auto-connect button ─────────────────────────────────────
              if (_mode == _DrawMode.connect && _dots.length >= 3)
                Positioned(
                  top: 12, right: 12,
                  child: GestureDetector(
                    onTap: _autoConnect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.15), blurRadius: 8)],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.auto_fix_high, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(context.tr('Auto-connect', 'خودکار جوڑ'),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),

              // ── My location button ──────────────────────────────────────
              Positioned(
                right: 14, bottom: 148,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _locating ? null : _gotoMyLocation,
                    child: SizedBox(
                      width: 44, height: 44,
                      child: Center(
                        child: _locating
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppTheme.primary))
                            : const Icon(Icons.my_location,
                                color: AppTheme.primary, size: 22),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Hint badge ──────────────────────────────────────────────
              Positioned(
                bottom: 140, left: 12, right: 68,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.64),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),

              // ── Bottom toolbar ──────────────────────────────────────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Material(
                  elevation: 10,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        if (closed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.straighten,
                                    size: 14, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '${_acres.toStringAsFixed(2)} ${context.tr('acres', 'ایکڑ')}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('boundary ready ✓', 'حدود تیار ✓'),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),

                        Row(children: [
                          OutlinedButton.icon(
                            onPressed: canUndo ? _undo : null,
                            icon: const Icon(Icons.undo, size: 17),
                            label: Text(context.tr('Undo', 'واپس')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: BorderSide(
                                  color: canUndo
                                      ? AppTheme.error
                                      : Colors.grey.shade300),
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: canUndo ? _clear : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: BorderSide(
                                  color: canUndo
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade300),
                              minimumSize: const Size(0, 44),
                            ),
                            child: Text(context.tr('Clear', 'صاف')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (closed && !widget.loading) ? widget.onSave : null,
                              icon: widget.loading
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(context.tr('Save Parcel', 'پلاٹ محفوظ کریں')),
                              style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 44)),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: widget.onSkip,
                          child: Text(
                            context.tr('Skip — save without boundary',
                                'چھوڑیں — بغیر حدود محفوظ کریں'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              decoration: TextDecoration.underline,
                            ),
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

// ── Numbered dot widget (Flutter widget — no canvas/bitmap needed) ──────────────

class _DotWidget extends StatelessWidget {
  final int  n;
  final bool isFirst;
  final bool isSelected;

  const _DotWidget({
    required this.n,
    required this.isFirst,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFFE65100)
        : isFirst
            ? const Color(0xFF1B5E20)
            : AppTheme.primary;

    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(
          color: Colors.black38,
          blurRadius: 4,
          offset: Offset(1, 2),
        )],
      ),
      child: Center(
        child: Text(
          '$n',
          style: TextStyle(
            color: Colors.white,
            fontSize: n >= 10 ? 11 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Step indicator dot ──────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final int num; final bool active; final String label;
  const _StepDot(this.num, this.active, this.label);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.grey.shade300,
          shape: BoxShape.circle),
        child: Center(child: Text('$num',
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.bold, fontSize: 12))),
      ),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(
          fontSize: 10,
          color: active ? AppTheme.primary : AppTheme.textSecondary)),
    ],
  );
}

// ── Shoelace formula → acres ────────────────────────────────────────────────────

double _shoelaceAcres(List<ll.LatLng> pts) {
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
  final cosLat = math.cos(avgLat * math.pi / 180).abs().clamp(0.0, 1.0);
  return sqDeg * 111 * 111 * cosLat * 247.105;
}
