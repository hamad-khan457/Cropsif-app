class Validators {
  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$', caseSensitive: false);
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final re = RegExp(r'^\+92\s?3\d{9}$|^03\d{9}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid Pakistani phone number (03XXXXXXXXX)';
    return null;
  }

  static String? cnic(String? v) {
    if (v == null || v.trim().isEmpty) return 'CNIC is required';
    final re = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    if (!re.hasMatch(v.trim())) return 'CNIC format: XXXXX-XXXXXXX-X';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must contain at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain at least one number';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    if (v.trim().length > 100) return 'Name must be at most 100 characters';
    return null;
  }

  static String? otp(String? v) {
    if (v == null || v.isEmpty) return 'OTP is required';
    if (v.length != 6) return 'OTP must be 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'OTP must contain digits only';
    return null;
  }
}