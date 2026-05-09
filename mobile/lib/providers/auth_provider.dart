import 'package:flutter/foundation.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/token_storage.dart';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();

  AuthState _state    = AuthState.unknown;
  UserModel? _user;
  bool _loading       = false;
  String? _error;
  int?    _errorCode;

  AuthState  get state     => _state;
  UserModel? get user      => _user;
  bool       get loading   => _loading;
  String?    get error     => _error;
  int?       get errorCode => _errorCode;

  void _setLoading(bool v) {
    _loading = v;
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  void _setError(dynamic e) {
    _loading = false;
    if (e is AppException) {
      _error     = e.message;
      _errorCode = e.statusCode;
    } else {
      _error     = e.toString();
      _errorCode = null;
    }
    notifyListeners();
  }

  // Called at app start
  Future<void> checkAuth() async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      _state = AuthState.authenticated;
    } else {
      final refresh = await TokenStorage.getRefreshToken();
      _state = refresh != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String cnic,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    try {
      await _repo.register(
        fullName: fullName, email: email, phone: phone,
        cnic: cnic, password: password, role: role,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    _setLoading(true);
    try {
      await _repo.verifyOtp(email: email, otp: otp);
      _state = AuthState.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    _setLoading(true);
    try {
      await _repo.resendOtp(email);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      _user  = await _repo.login(email: email, password: password);
      _state = AuthState.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _repo.logout();
    _user  = null;
    _state = AuthState.unauthenticated;
    _loading = false;
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _repo.forgotPassword(email);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> sendPasswordResetOtp(String email) async {
    _setLoading(true);
    try {
      await _repo.sendPasswordResetOtp(email);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _repo.resetPasswordWithOtp(
          email: email, otp: otp, newPassword: newPassword);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _repo.resetPassword(token: token, newPassword: newPassword);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }
}