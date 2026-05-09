class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? cnic;
  final String role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.cnic,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:         json['id'] as String,
        fullName:   (json['full_name'] ?? json['fullName'] ?? '') as String,
        email:      json['email'] as String,
        phone:      json['phone'] as String?,
        cnic:       json['cnic']  as String?,
        role:       json['role']  as String,
        isVerified: (json['is_verified'] ?? json['isVerified'] ?? false) as bool,
        isActive:   (json['is_active']   ?? json['isActive']  ?? true)  as bool,
        createdAt:  json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  String get roleLabel {
    switch (role) {
      case 'landowner': return 'Landowner';
      case 'manager':   return 'Farm Manager';
      case 'worker':    return 'Field Worker';
      case 'admin':     return 'Administrator';
      default:          return role;
    }
  }

  String get roleLabelUrdu {
    switch (role) {
      case 'landowner': return 'زمیندار';
      case 'manager':   return 'فارم منیجر';
      case 'worker':    return 'فیلڈ ورکر';
      case 'admin':     return 'ایڈمن';
      default:          return role;
    }
  }

  String localizedRoleLabel(bool isUrdu) =>
      isUrdu ? roleLabelUrdu : roleLabel;
}