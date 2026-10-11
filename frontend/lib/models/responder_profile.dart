import 'emergency.dart';

enum VerificationStatus {
  unverified('UNVERIFIED', 'Unverified'),
  pending('PENDING', 'Pending Verification'),
  verified('VERIFIED', 'Verified Responder'),
  revoked('REVOKED', 'Verification Revoked');

  final String value;
  final String label;
  const VerificationStatus(this.value, this.label);

  static VerificationStatus fromString(String val) {
    return VerificationStatus.values.firstWhere(
      (v) => v.value == val,
      orElse: () => VerificationStatus.unverified,
    );
  }
}

class ResponderProfileModel {
  final String userId;
  final VerificationStatus verificationStatus;
  final bool available;
  final List<String> capabilities;
  final LatLngCoordinates? location;
  final DateTime? locationUpdatedAt;
  final int completedCount;
  final int reputationScore;

  const ResponderProfileModel({
    required this.userId,
    required this.verificationStatus,
    required this.available,
    required this.capabilities,
    this.location,
    this.locationUpdatedAt,
    this.completedCount = 0,
    this.reputationScore = 0,
  });

  bool get isEligibleForDispatch =>
      verificationStatus == VerificationStatus.verified && available;

  factory ResponderProfileModel.fromJson(Map<String, dynamic> json) {
    return ResponderProfileModel(
      userId: json['userId'] ?? '',
      verificationStatus: VerificationStatus.fromString(
        json['verificationStatus'] ?? 'UNVERIFIED',
      ),
      available: json['available'] ?? false,
      capabilities: List<String>.from(json['capabilities'] ?? []),
      location: json['location'] != null
          ? LatLngCoordinates.fromJson(json['location'])
          : null,
      locationUpdatedAt: json['locationUpdatedAt'] != null
          ? DateTime.tryParse(json['locationUpdatedAt'])
          : null,
      completedCount: json['completedCount'] ?? 0,
      reputationScore: json['reputationScore'] ?? 0,
    );
  }
}
