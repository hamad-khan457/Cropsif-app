import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.accessToken,  value: accessToken),
      _storage.write(key: AppConstants.refreshToken, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken()  => _storage.read(key: AppConstants.accessToken);
  static Future<String?> getRefreshToken() => _storage.read(key: AppConstants.refreshToken);

  static Future<void> saveUserMeta({required String id, required String role}) async {
    await Future.wait([
      _storage.write(key: AppConstants.userId,   value: id),
      _storage.write(key: AppConstants.userRole, value: role),
    ]);
  }

  static Future<String?> getUserRole() => _storage.read(key: AppConstants.userRole);
  static Future<String?> getUserId()   => _storage.read(key: AppConstants.userId);

  static Future<void> clear() => _storage.deleteAll();
}