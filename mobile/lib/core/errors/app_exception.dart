class AppException implements Exception {
  final String message;
  final int? statusCode;
  final List<Map<String, String>>? fieldErrors;

  const AppException(this.message, {this.statusCode, this.fieldErrors});

  @override
  String toString() => message;
}