import 'package:flutter/foundation.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_model.dart';
import '../data/models/notification_prefs_model.dart';

class UserProvider extends ChangeNotifier {
  final _repo = UserRepository();

  UserModel? _user;
  NotificationPrefsModel? _prefs;
  bool _loading = false;
  String? _error;

  UserModel? get user   => _user;
  NotificationPrefsModel? get prefs => _prefs;
  bool get loading      => _loading;
  String? get error     => _error;

  void _setLoading(bool v)  { _loading = v; _error = null; notifyListeners(); }
  void _setError(String msg){ _loading = false; _error = msg; notifyListeners(); }

  Future<void> loadProfile() async {
    _setLoading(true);
    try {
      _user = await _repo.getProfile();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> updateProfile({String? fullName, String? phone}) async {
    _setLoading(true);
    try {
      _user = await _repo.updateProfile(fullName: fullName, phone: phone);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> loadNotificationPrefs() async {
    _setLoading(true);
    try {
      _prefs = await _repo.getNotificationPrefs();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> updateNotificationPrefs(NotificationPrefsModel prefs) async {
    _setLoading(true);
    try {
      _prefs = await _repo.updateNotificationPrefs(prefs);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deactivateAccount(String password) async {
    _setLoading(true);
    try {
      await _repo.deactivateAccount(password);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> exportData() async {
    _setLoading(true);
    try {
      final data = await _repo.exportData();
      _loading = false;
      notifyListeners();
      return data;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}