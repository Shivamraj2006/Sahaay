enum UserRole {
  elderlyUser('ELDERLY_USER', 'Elderly User'),
  volunteer('VOLUNTEER', 'Volunteer Responder'),
  medicalProfessional('MEDICAL_PROFESSIONAL', 'Medical Professional'),
  organizationCoordinator('ORGANIZATION_COORDINATOR', 'Coordinator'),
  verifier('VERIFIER', 'Verifier'),
  admin('ADMIN', 'Administrator');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  static UserRole fromString(String val) {
    return UserRole.values.firstWhere(
      (r) => r.value == val,
      orElse: () => UserRole.elderlyUser,
    );
  }
}

class UserModel {
  final String id;
  final String displayName;
  final String phone;
  final UserRole role;
  final bool isGuest;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.role,
    this.isGuest = false,
    this.createdAt,
  });

  bool get isElderly => role == UserRole.elderlyUser;
  bool get isResponder =>
      role == UserRole.volunteer ||
      role == UserRole.medicalProfessional ||
      role == UserRole.organizationCoordinator;
  bool get isAdminOrVerifier =>
      role == UserRole.admin || role == UserRole.verifier;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      displayName: json['displayName'] ?? '',
      phone: json['phone'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'ELDERLY_USER'),
      isGuest: json['isGuest'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'phone': phone,
      'role': role.value,
      'isGuest': isGuest,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
