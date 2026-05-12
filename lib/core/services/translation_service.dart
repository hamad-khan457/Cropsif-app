import 'dart:convert';
import 'package:http/http.dart' as http;

/// Translates Urdu text → English using the MyMemory free API.
/// No API key required (free tier: ~5 000 words/day per IP).
///
/// To switch to Google Cloud Translation API instead, replace the body of
/// [urduToEnglish] with a call to:
///   POST https://translation.googleapis.com/language/translate/v2
///   ?key=YOUR_GOOGLE_API_KEY&q={text}&source=ur&target=en
class TranslationService {
  TranslationService._();

  static bool _hasUrduChars(String text) =>
      text.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

  /// Returns the English translation of [text].
  /// If [text] contains no Urdu characters, it is returned unchanged.
  static Future<String> urduToEnglish(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !_hasUrduChars(trimmed)) return trimmed;
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(trimmed)}&langpair=ur|en',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'CropsifyApp/1.0'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final translated =
            json['responseData']?['translatedText'] as String?;
        if (translated != null && translated.trim().isNotEmpty) {
          return translated.trim();
        }
      }
    } catch (_) {}
    return trimmed; // fallback: original text
  }

  /// Translates a list of strings in one batch (sequential calls).
  static Future<List<String>> urduListToEnglish(List<String> texts) async {
    final results = <String>[];
    for (final t in texts) {
      results.add(await urduToEnglish(t));
    }
    return results;
  }
}
