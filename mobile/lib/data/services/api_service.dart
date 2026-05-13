import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/token_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  ApiService._();
  factory ApiService() => _instance;

  final _client = http.Client();
  static const _timeout = Duration(seconds: 15);

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ── Public (no auth) ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    try {
      final res = await _client
          .post(Uri.parse(url), headers: _headers(), body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(res);
    } on SocketException {
      throw const AppException(
        'Cannot reach server. Make sure your phone and PC are on the same Wi-Fi.',
        statusCode: 0,
      );
    } on TimeoutException {
      throw const AppException(
        'Request timed out. Please try again.',
        statusCode: 0,
      );
    }
  }

  // ── Authenticated ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> authGet(String url) async {
    try {
      final token = await _getValidToken();
      final res = await _client
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(_timeout);
      return _parse(res);
    } on SocketException {
      throw const AppException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const AppException('Request timed out. Please try again.', statusCode: 0);
    }
  }

  Future<Map<String, dynamic>> authPost(String url, Map<String, dynamic> body) async {
    try {
      final token = await _getValidToken();
      final res = await _client
          .post(Uri.parse(url), headers: _headers(token: token), body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(res);
    } on SocketException {
      throw const AppException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const AppException('Request timed out. Please try again.', statusCode: 0);
    }
  }

  Future<Map<String, dynamic>> authPatch(String url, Map<String, dynamic> body) async {
    try {
      final token = await _getValidToken();
      final res = await _client
          .patch(Uri.parse(url), headers: _headers(token: token), body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(res);
    } on SocketException {
      throw const AppException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const AppException('Request timed out. Please try again.', statusCode: 0);
    }
  }

  Future<Map<String, dynamic>> authPut(String url, Map<String, dynamic> body) async {
    try {
      final token = await _getValidToken();
      final res = await _client
          .put(Uri.parse(url), headers: _headers(token: token), body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(res);
    } on SocketException {
      throw const AppException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const AppException('Request timed out. Please try again.', statusCode: 0);
    }
  }

  Future<Map<String, dynamic>> authPostFile(String url, String filePath) async {
    try {
      final token = await _getValidToken();
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      // Always declare an explicit image MIME type so the backend's file-type
      // filter never rejects the upload as application/octet-stream.
      final ext = filePath.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'png'  => MediaType('image', 'png'),
        'webp' => MediaType('image', 'webp'),
        'gif'  => MediaType('image', 'gif'),
        _      => MediaType('image', 'jpeg'), // jpg / heic / unknown → jpeg
      };

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        filePath,
        contentType: mime,
      ));

      final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      return _parse(res);
    } on SocketException {
      throw const AppException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const AppException('Scan timed out. Please try again.', statusCode: 0);
    }
  }

  Future<Map<String, dynamic>> authDelete(String url, Map<String, dynamic> body) async {
    try {
      final token = await _getValidToken();
      final req = http.Request('DELETE', Uri.parse(url))
        ..headers.addAll(_headers(token: token))
        ..body = jsonEncode(body);
      final streamed = await _client.send(req).timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      return _parse(res);
    } on SocketException {
      throw const AppException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const AppException('Request timed out. Please try again.', statusCode: 0);
    }
  }

  // ── Token refresh ─────────────────────────────────────────────────────────────

  Future<String> _getValidToken() async {
    final access = await TokenStorage.getAccessToken();
    if (access != null && !_isExpired(access)) return access;

    final refresh = await TokenStorage.getRefreshToken();
    if (refresh == null) {
      throw const AppException('Session expired. Please log in again.', statusCode: 401);
    }

    final res = await _client
        .post(
          Uri.parse(ApiConstants.refresh),
          headers: _headers(),
          body: jsonEncode({'refreshToken': refresh}),
        )
        .timeout(_timeout);
    final data   = _parse(res);
    final tokens = data['data'] as Map<String, dynamic>;
    await TokenStorage.saveTokens(
      accessToken:  tokens['accessToken']  as String,
      refreshToken: tokens['refreshToken'] as String,
    );
    return tokens['accessToken'] as String;
  }

  bool _isExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          .isBefore(DateTime.now().add(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }

  // ── Response parser ───────────────────────────────────────────────────────────

  Map<String, dynamic> _parse(http.Response res) {
    // Guard against non-JSON bodies (HTML error pages, plain text, etc.)
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw AppException(
        res.statusCode >= 500
            ? 'Server error (${res.statusCode}). Please try again later.'
            : 'Unexpected response from server. Please try again.',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final message = body['message'] as String? ?? 'Something went wrong';
    final errors  = (body['errors'] as List?)
        ?.map((e) => Map<String, String>.from(e as Map))
        .toList();
    throw AppException(message, statusCode: res.statusCode, fieldErrors: errors);
  }
}