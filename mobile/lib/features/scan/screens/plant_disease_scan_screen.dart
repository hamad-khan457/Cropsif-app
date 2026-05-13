import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/language_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';

// ── Status ─────────────────────────────────────────────────────────────────────

enum _ScanStatus { healthy, warning, danger }

// ── Scan record ────────────────────────────────────────────────────────────────

class _ScanRecord {
  final String disease;
  final String diseaseUr;
  final String rawLabel;
  final double confidence;
  final _ScanStatus status;
  final DateTime scanTime;

  const _ScanRecord({
    required this.disease,
    required this.diseaseUr,
    required this.rawLabel,
    required this.confidence,
    required this.status,
    required this.scanTime,
  });

  factory _ScanRecord.fromApi(Map<String, dynamic> json) {
    final disease   = json['disease']   as String;
    final rawLabel  = json['raw_label'] as String? ?? disease;
    final confidence = (json['confidence'] as num).toDouble();
    final status = switch (json['status'] as String? ?? 'warning') {
      'healthy' => _ScanStatus.healthy,
      'danger'  => _ScanStatus.danger,
      _         => _ScanStatus.warning,
    };
    return _ScanRecord(
      disease:    disease,
      diseaseUr:  _urduName(rawLabel),
      rawLabel:   rawLabel,
      confidence: confidence,
      status:     status,
      scanTime:   DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(scanTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours   < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays    < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get treatmentEn => _treatmentEn(rawLabel);
  String get treatmentUr => _treatmentUr(rawLabel);
}

// ── Urdu name lookup ───────────────────────────────────────────────────────────

const _urduNames = <String, String>{
  'Apple___Apple_scab':                                   'سیب کی کھرنڈ',
  'Apple___Black_rot':                                    'سیب کا سیاہ سڑن',
  'Apple___Cedar_apple_rust':                             'سیب کا زنگ',
  'Apple___healthy':                                      'سیب صحت مند',
  'Blueberry___healthy':                                  'بلو بیری صحت مند',
  'Cherry_(including_sour)___Powdery_mildew':             'چیری کا پاؤڈری پھپھوند',
  'Cherry_(including_sour)___healthy':                    'چیری صحت مند',
  'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot':   'مکئی کا دھبہ',
  'Corn_(maize)___Common_rust_':                          'مکئی کا زنگ',
  'Corn_(maize)___Northern_Leaf_Blight':                  'مکئی کا جھلساؤ',
  'Corn_(maize)___healthy':                               'مکئی صحت مند',
  'Grape___Black_rot':                                    'انگور کا سیاہ سڑن',
  'Grape___Esca_(Black_Measles)':                         'انگور کا خسرہ',
  'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)':           'انگور کا جھلساؤ',
  'Grape___healthy':                                      'انگور صحت مند',
  'Orange___Haunglongbing_(Citrus_greening)':             'سنترے کی سبزی بیماری',
  'Peach___Bacterial_spot':                               'آڑو کا بیکٹیریا دھبہ',
  'Peach___healthy':                                      'آڑو صحت مند',
  'Pepper,_bell___Bacterial_spot':                        'مرچ کا بیکٹیریا دھبہ',
  'Pepper,_bell___healthy':                               'مرچ صحت مند',
  'Potato___Early_blight':                                'آلو کا ابتدائی جھلساؤ',
  'Potato___Late_blight':                                 'آلو کا دیر سے جھلساؤ',
  'Potato___healthy':                                     'آلو صحت مند',
  'Raspberry___healthy':                                  'رسبری صحت مند',
  'Soybean___healthy':                                    'سویابین صحت مند',
  'Squash___Powdery_mildew':                              'کدو کا پاؤڈری پھپھوند',
  'Strawberry___Leaf_scorch':                             'اسٹرابیری کا پتہ جلن',
  'Strawberry___healthy':                                 'اسٹرابیری صحت مند',
  'Tomato___Bacterial_spot':                              'ٹماٹر کا بیکٹیریا دھبہ',
  'Tomato___Early_blight':                                'ٹماٹر کا ابتدائی جھلساؤ',
  'Tomato___Late_blight':                                 'ٹماٹر کا دیر سے جھلساؤ',
  'Tomato___Leaf_Mold':                                   'ٹماٹر کا پتہ پھپھوند',
  'Tomato___Septoria_leaf_spot':                          'ٹماٹر کا سیپٹوریا دھبہ',
  'Tomato___Spider_mites Two-spotted_spider_mite':        'ٹماٹر مکڑی کا حملہ',
  'Tomato___Target_Spot':                                 'ٹماٹر کا ہدف دھبہ',
  'Tomato___Tomato_Yellow_Leaf_Curl_Virus':               'ٹماٹر یلو لیف وائرس',
  'Tomato___Tomato_mosaic_virus':                         'ٹماٹر موزیک وائرس',
  'Tomato___healthy':                                     'ٹماٹر صحت مند',
  'rice_BrownSpot':                                       'چاول کا بھورا دھبہ',
  'rice_Healthy':                                         'چاول صحت مند',
  'rice_Hispa':                                           'چاول ہسپا',
  'rice_LeafBlast':                                       'چاول کا جھلساؤ',
  'cotton_diseased cotton leaf':                          'کپاس بیمار پتہ',
  'cotton_diseased cotton plant':                         'کپاس بیمار پودا',
  'cotton_fresh cotton leaf':                             'کپاس تازہ پتہ',
  'cotton_fresh cotton plant':                            'کپاس تازہ پودا',
  'wheat_BrownRust':                                      'گندم کا بھورا زنگ',
  'wheat_Healthy':                                        'گندم صحت مند',
  'wheat_Mildew':                                         'گندم پھپھوند',
  'wheat_Septoria':                                       'گندم سیپٹوریا',
  'wheat_YellowRust':                                     'گندم کا زرد زنگ',
};

String _urduName(String raw) => _urduNames[raw] ?? raw;

// ── Treatment advice ───────────────────────────────────────────────────────────

String _treatmentEn(String raw) {
  final lo = raw.toLowerCase();
  if (lo.contains('healthy') || lo.contains('fresh')) return '';
  if (lo.contains('blight'))    return 'Apply copper-based fungicide. Remove infected leaves immediately. Re-inspect in 5 days.';
  if (lo.contains('rust'))      return 'Apply triazole fungicide (Propiconazole). Avoid overhead irrigation.';
  if (lo.contains('mildew'))    return 'Apply sulfur-based fungicide. Improve air circulation around plants.';
  if (lo.contains('rot'))       return 'Remove infected plant parts. Apply Mancozeb fungicide at 2.5 g/L.';
  if (lo.contains('spot'))      return 'Apply copper fungicide at first signs. Avoid wetting foliage during irrigation.';
  if (lo.contains('virus') || lo.contains('mosaic')) return 'No chemical cure. Remove infected plants and control insect vectors.';
  if (lo.contains('bacterial')) return 'Apply copper-based bactericide. Avoid field work when plants are wet.';
  if (lo.contains('blast'))     return 'Apply tricyclazole fungicide. Drain fields and reduce nitrogen fertilizer.';
  if (lo.contains('hispa'))     return 'Remove and destroy affected leaves. Apply recommended insecticide.';
  return 'Consult an agronomist for specific treatment advice.';
}

String _treatmentUr(String raw) {
  final lo = raw.toLowerCase();
  if (lo.contains('healthy') || lo.contains('fresh')) return '';
  if (lo.contains('blight'))    return 'تانبے پر مبنی پھپھوندی کش لگائیں۔ متاثرہ پتے فوری ہٹائیں۔ 5 دن بعد معائنہ کریں۔';
  if (lo.contains('rust'))      return 'ٹرائیازول پھپھوندی کش لگائیں۔ اوپر سے پانی دینے سے گریز کریں۔';
  if (lo.contains('mildew'))    return 'گندھک پر مبنی پھپھوندی کش لگائیں۔ پودوں کے گرد ہوا کی گردش بہتر کریں۔';
  if (lo.contains('rot'))       return 'متاثرہ حصے ہٹائیں۔ مینکوزیب 2.5 گرام فی لیٹر لگائیں۔';
  if (lo.contains('spot'))      return 'ابتدائی علامات پر تانبا پھپھوندی کش لگائیں۔ پانی دیتے وقت پتوں کو گیلا کرنے سے بچیں۔';
  if (lo.contains('virus') || lo.contains('mosaic')) return 'کیمیائی علاج نہیں۔ متاثرہ پودے ہٹائیں اور کیڑوں کو کنٹرول کریں۔';
  if (lo.contains('bacterial')) return 'تانبے پر مبنی بیکٹیریا کش لگائیں۔ گیلے حالات میں کام سے گریز کریں۔';
  if (lo.contains('blast'))     return 'ٹرائی سائکلازول پھپھوندی کش لگائیں۔ کھیت سے پانی نکالیں اور نائٹروجن کم کریں۔';
  if (lo.contains('hispa'))     return 'متاثرہ پتے ہٹائیں۔ تجویز کردہ کیڑے مار دوا استعمال کریں۔';
  return 'مخصوص علاج کے لیے زرعی ماہر سے رجوع کریں۔';
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class PlantDiseaseScanScreen extends StatefulWidget {
  const PlantDiseaseScanScreen({super.key});

  @override
  State<PlantDiseaseScanScreen> createState() => _PlantDiseaseScanScreenState();
}

class _PlantDiseaseScanScreenState extends State<PlantDiseaseScanScreen> {
  final _picker = ImagePicker();

  XFile?        _pickedImage;
  _ScanRecord?  _lastScan;
  bool          _scanning = false;
  final List<_ScanRecord> _history = [];

  // ── Image picking ─────────────────────────────────────────────────────────────

  Future<void> _pickAndScan(ImageSource source) async {
    final image = await _picker.pickImage(
      source:       source,
      imageQuality: 85,
      maxWidth:     1024,
    );
    if (image == null || !mounted) return;

    setState(() {
      _pickedImage = image;
      _scanning    = true;
    });

    await _runPrediction(image.path);
  }

  Future<void> _runPrediction(String filePath) async {
    try {
      final data   = await ApiService().authPostFile(ApiConstants.scanPredict, filePath);
      if (!mounted) return;
      final record = _ScanRecord.fromApi(data);
      setState(() {
        if (_lastScan != null) _history.insert(0, _lastScan!);
        _lastScan = record;
        _scanning = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _scanning = false);
      _showError('Scan failed. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<LanguageProvider>().isUrdu;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: const BackButton(),
        title: Text(
          isUrdu ? 'پودوں کی بیماری اسکین' : 'Plant Disease Scan',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          if (_history.isNotEmpty)
            TextButton(
              onPressed: () => _showHistorySheet(context, isUrdu),
              child: Text(
                isUrdu ? 'تاریخ' : 'History',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _ImageCaptureArea(
            scanning:     _scanning,
            pickedImage:  _pickedImage,
            isUrdu:       isUrdu,
          ),
          const SizedBox(height: 14),
          _CameraGalleryRow(
            scanning:  _scanning,
            isUrdu:    isUrdu,
            onCamera:  () => _pickAndScan(ImageSource.camera),
            onGallery: () => _pickAndScan(ImageSource.gallery),
          ),
          const SizedBox(height: 28),
          _SectionTitle(
            en: _lastScan != null ? 'Scan Result' : 'Last Scan Result',
            ur: _lastScan != null ? 'اسکین نتیجہ' : 'آخری اسکین نتیجہ',
            isUrdu: isUrdu,
          ),
          const SizedBox(height: 10),
          if (_lastScan != null)
            _LastScanCard(scan: _lastScan!, isUrdu: isUrdu)
          else
            _NoScanYet(isUrdu: isUrdu),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 28),
            _SectionTitle(en: 'Scan History', ur: 'اسکین تاریخ', isUrdu: isUrdu),
            const SizedBox(height: 10),
            ..._history.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryRow(scan: r, isUrdu: isUrdu),
                )),
          ],
        ],
      ),
    );
  }

  void _showHistorySheet(BuildContext context, bool isUrdu) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isUrdu ? 'اسکین تاریخ' : 'Scan History',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ..._history.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryRow(scan: r, isUrdu: isUrdu),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Image Capture Area ─────────────────────────────────────────────────────────

class _ImageCaptureArea extends StatelessWidget {
  final bool   scanning;
  final XFile? pickedImage;
  final bool   isUrdu;

  const _ImageCaptureArea({
    required this.scanning,
    required this.pickedImage,
    required this.isUrdu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (pickedImage != null)
            Image.file(File(pickedImage!.path), fit: BoxFit.cover)
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    size: 48, color: Color(0xFF9E9E9E)),
                const SizedBox(height: 10),
                Text(
                  isUrdu ? 'پتے کی تصویر لیں' : 'Tap to capture leaf image',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'JPEG / PNG · max 10 MB',
                  style: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD)),
                ),
              ],
            ),
          // Overlay while scanning
          if (scanning)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    isUrdu ? 'تجزیہ ہو رہا ہے...' : 'Analyzing leaf...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Camera / Gallery Row ───────────────────────────────────────────────────────

class _CameraGalleryRow extends StatelessWidget {
  final bool          scanning;
  final bool          isUrdu;
  final VoidCallback  onCamera;
  final VoidCallback  onGallery;

  const _CameraGalleryRow({
    required this.scanning,
    required this.isUrdu,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: scanning ? null : onCamera,
            icon:  const Icon(Icons.camera_alt, size: 18),
            label: Text(isUrdu ? 'کیمرہ' : 'Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize:     const Size(0, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: scanning ? null : onGallery,
            icon:  const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(isUrdu ? 'گیلری' : 'Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF424242),
              side:            const BorderSide(color: Color(0xFFBDBDBD)),
              minimumSize:     const Size(0, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section Title ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String en;
  final String ur;
  final bool   isUrdu;
  const _SectionTitle({
    required this.en,
    required this.ur,
    required this.isUrdu,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      isUrdu ? ur : en,
      style: const TextStyle(
        fontSize:   16,
        fontWeight: FontWeight.bold,
        color:      Color(0xFF1A1A1A),
      ),
    );
  }
}

// ── No scan yet ────────────────────────────────────────────────────────────────

class _NoScanYet extends StatelessWidget {
  final bool isUrdu;
  const _NoScanYet({required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco_outlined, size: 40, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 10),
          Text(
            isUrdu ? 'ابھی تک کوئی اسکین نہیں' : 'No scan yet',
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            isUrdu ? 'پتے کی تصویر لے کر شروع کریں' : 'Capture a leaf to get started',
            style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Last Scan Card ─────────────────────────────────────────────────────────────

class _LastScanCard extends StatelessWidget {
  final _ScanRecord scan;
  final bool        isUrdu;
  const _LastScanCard({required this.scan, required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    final (cardBg, iconColor, badgeBg, badgeFg) = switch (scan.status) {
      _ScanStatus.danger  => (
          const Color(0xFFFFF3F3),
          const Color(0xFFD32F2F),
          const Color(0xFFFFEBEE),
          const Color(0xFFD32F2F),
        ),
      _ScanStatus.warning => (
          const Color(0xFFFFF8E1),
          const Color(0xFFFF8F00),
          const Color(0xFFFFF8E1),
          const Color(0xFFFF8F00),
        ),
      _ScanStatus.healthy => (
          const Color(0xFFE8F5E9),
          AppTheme.primary,
          const Color(0xFFE8F5E9),
          AppTheme.primary,
        ),
    };

    final borderColor = switch (scan.status) {
      _ScanStatus.danger  => const Color(0xFFFFCDD2),
      _ScanStatus.warning => const Color(0xFFFFE0B2),
      _ScanStatus.healthy => const Color(0xFFC8E6C9),
    };

    final dividerColor = borderColor;

    final treatment = isUrdu ? scan.treatmentUr : scan.treatmentEn;

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disease row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(
                  scan.status == _ScanStatus.healthy
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: iconColor,
                  size:  22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrdu ? scan.diseaseUr : scan.disease,
                        style: const TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scan.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color:    Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        badgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(color: badgeFg.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${scan.confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.bold,
                      color:      badgeFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Treatment advice
          if (treatment.isNotEmpty) ...[
            Divider(height: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color:    Color(0xFF424242),
                          height:   1.5,
                        ),
                        children: [
                          TextSpan(
                            text:  isUrdu ? 'علاج کا مشورہ: ' : 'Treatment Advice: ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: treatment),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── History Row ────────────────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  final _ScanRecord scan;
  final bool        isUrdu;
  const _HistoryRow({required this.scan, required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (scan.status) {
      _ScanStatus.healthy => AppTheme.primary,
      _ScanStatus.warning => const Color(0xFFFF8F00),
      _ScanStatus.danger  => const Color(0xFFD32F2F),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width:  10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? scan.diseaseUr : scan.disease,
                  style: const TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                    color:      Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scan.timeAgo,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color:        dotColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${scan.confidence.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.bold,
                color:      dotColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
