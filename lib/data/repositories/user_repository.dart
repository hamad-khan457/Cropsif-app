import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/notification_prefs_model.dart';

class UserRepository {
  final _api = ApiService();

  Future<UserModel> getProfile() async {
    final res = await _api.authGet(ApiConstants.me);
    return UserModel.fromJson(res['data']['profile'] as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile({String? fullName, String? phone}) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phone    != null) body['phone']    = phone;
    final res = await _api.authPatch(ApiConstants.me, body);
    return UserModel.fromJson(res['data']['user'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.authPut(ApiConstants.mePassword, {
      'currentPassword': currentPassword,
      'newPassword':     newPassword,
    });
  }

  Future<NotificationPrefsModel> getNotificationPrefs() async {
    final res = await _api.authGet(ApiConstants.meNotifications);
    final prefs = res['data']['preferences'];
    if (prefs == null) return const NotificationPrefsModel();
    return NotificationPrefsModel.fromJson(prefs as Map<String, dynamic>);
  }

  Future<NotificationPrefsModel> updateNotificationPrefs(NotificationPrefsModel prefs) async {
    final res = await _api.authPut(ApiConstants.meNotifications, prefs.toJson());
    return NotificationPrefsModel.fromJson(
      res['data']['preferences'] as Map<String, dynamic>,
    );
  }

  Future<void> deactivateAccount(String password) async {
    await _api.authDelete(ApiConstants.me, {'password': password});
  }

  Future<Map<String, dynamic>> exportData() async {
    final res = await _api.authGet(ApiConstants.meExport);
    return res['data']['export'] as Map<String, dynamic>;
  }
}