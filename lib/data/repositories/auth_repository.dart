import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/token_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String cnic,
    required String password,
    required String role,
  }) async {
    final res = await _api.post(ApiConstants.register, {
      'fullName': fullName,
      'email':    email,
      'phone':    phone,
      'cnic':     cnic,
      'password': password,
      'role':     role,
    });
    return res['data'] as Map<String, dynamic>;
  }

  // Flutter sends { email, otp } — backend now accepts these fields directly
  Future<void> verifyOtp({required String email, required String otp}) async {
    final res  = await _api.post(ApiConstants.verifyOtp, {
      'email':   email,
      'otp':     otp,
      'otpType': 'email_verification',
    });
    final data = res['data'] as Map<String, dynamic>;

    // Backend auto-logs in after verification — save the returned tokens
    await TokenStorage.saveTokens(
      accessToken:  data['accessToken']  as String,
      refreshToken: data['refreshToken'] as String,
    );
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await TokenStorage.saveUserMeta(id: user.id, role: user.role);
  }

  // Flutter sends { email } — backend looks up userId internally
  Future<void> resendOtp(String email) async {
    await _api.post(ApiConstants.resendOtp, {
      'email':   email,
      'otpType': 'email_verification',
    });
  }

  // Flutter sends { email, password } — backend accepts both email and identifier
  Future<UserModel> login({required String email, required String password}) async {
    final res  = await _api.post(ApiConstants.login, {
      'identifier': email,   // backend accepts email via identifier field
      'password':   password,
    });
    final data = res['data'] as Map<String, dynamic>;
    await TokenStorage.saveTokens(
      accessToken:  data['accessToken']  as String,
      refreshToken: data['refreshToken'] as String,
    );
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await TokenStorage.saveUserMeta(id: user.id, role: user.role);
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.authPost(ApiConstants.logout, {});
    } finally {
      await TokenStorage.clear();
    }
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(ApiConstants.forgotPassword, {'email': email});
  }

  /// OTP-based flow: sends 6-digit code to email
  Future<void> sendPasswordResetOtp(String email) async {
    await _api.post(ApiConstants.forgotPasswordOtp, {'email': email});
  }

  /// OTP-based flow: verifies code + resets password in one call
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _api.post(ApiConstants.resetPasswordOtp, {
      'email':       email,
      'otp':         otp,
      'newPassword': newPassword,
    });
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post(ApiConstants.resetPassword, {
      'token':       token,
      'newPassword': newPassword,
    });
  }
}