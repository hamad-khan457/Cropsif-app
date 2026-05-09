import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _key = 'cropsify_is_urdu';

  bool _isUrdu = false;
  bool get isUrdu => _isUrdu;

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isUrdu = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isUrdu = !_isUrdu;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isUrdu);
  }

  Future<void> setUrdu(bool value) async {
    if (_isUrdu == value) return;
    _isUrdu = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isUrdu);
  }

  String t(String en, String ur) => _isUrdu ? ur : en;
}
