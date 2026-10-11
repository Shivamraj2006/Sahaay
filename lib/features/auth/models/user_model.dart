enum UserRole {
  elderlyUser('ELDERLY_USER', 'Elderly User / Citizen'),
  volunteer('VOLUNTEER', 'Community Volunteer Responder'),
  medicalProfessional('MEDICAL_PROFESSIONAL', 'Medical Professional Responder'),
  organizationCoordinator('ORGANIZATION_COORDINATOR', 'NGO / Org Coordinator'),
  verifier('VERIFIER', 'Verification Officer'),
  admin('ADMIN', 'System Administrator');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.elderlyUser;
    for (final r in UserRole.values) {
      if (r.value.toUpperCase() == role.toUpperCase()) return r;
    }
    return UserRole.elderlyUser;
  }

  bool get isResponder =>
      this == UserRole.volunteer || this == UserRole.medicalProfessional;

  bool get isAdminOrVerifier =>
      this == UserRole.verifier || this == UserRole.admin;
}

enum VerificationStatus {
  unverified('UNVERIFIED', 'Unverified'),
  pending('PENDING', 'Pending Verification'),
  verified('VERIFIED', 'Verified Responder'),
  revoked('REVOKED', 'Verification Revoked');

  final String value;
  final String label;
  const VerificationStatus(this.value, this.label);

  static VerificationStatus fromString(String? status) {
    if (status == null) return VerificationStatus.unverified;
    for (final s in VerificationStatus.values) {
      if (s.value.toUpperCase() == status.toUpperCase()) return s;
    }
    return VerificationStatus.unverified;
  }
}

class UserModel {
  final String id;
  final String displayName;
  final String phone;
  final UserRole role;
  final VerificationStatus verificationStatus;
  final bool? isAvailable;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.role,
    this.verificationStatus = VerificationStatus.unverified,
    this.isAvailable,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'User',
      phone: json['phone'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? json['requestedRole'] as String?),
      verificationStatus: VerificationStatus.fromString(json['verificationStatus'] as String?),
      isAvailable: json['isAvailable'] as bool? ?? json['available'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'phone': phone,
      'role': role.value,
      'verificationStatus': verificationStatus.value,
      'isAvailable': isAvailable,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
