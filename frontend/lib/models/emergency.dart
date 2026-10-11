enum EmergencyCategory {
  medical('MEDICAL', 'Medical Emergency'),
  fallInjury('FALL_INJURY', 'Fall / Injury'),
  hospitalAssistance('HOSPITAL_ASSISTANCE', 'Need Hospital');

  final String value;
  final String label;
  const EmergencyCategory(this.value, this.label);

  static EmergencyCategory fromString(String val) {
    return EmergencyCategory.values.firstWhere(
      (c) => c.value == val,
      orElse: () => EmergencyCategory.medical,
    );
  }
}

enum EmergencyStatus {
  active('ACTIVE', 'Active (Looking for Responders)'),
  assigned('ASSIGNED', 'Responder Assigned'),
  responderArrived('RESPONDER_ARRIVED', 'Responder Arrived on Scene'),
  escalated('ESCALATED', 'Escalated to Emergency Services'),
  resolved('RESOLVED', 'Resolved & Safe'),
  cancelled('CANCELLED', 'Cancelled');

  final String value;
  final String label;
  const EmergencyStatus(this.value, this.label);

  static EmergencyStatus fromString(String val) {
    return EmergencyStatus.values.firstWhere(
      (s) => s.value == val,
      orElse: () => EmergencyStatus.active,
    );
  }

  bool get isTerminal => this == resolved || this == cancelled;
  bool get isActiveOrAssigned => this == active || this == assigned || this == responderArrived || this == escalated;
}

enum ProofStatus {
  notSubmitted('NOT_SUBMITTED'),
  pending('PENDING'),
  confirmed('CONFIRMED'),
  failed('FAILED');

  final String value;
  const ProofStatus(this.value);

  static ProofStatus fromString(String val) {
    return ProofStatus.values.firstWhere(
      (p) => p.value == val,
      orElse: () => ProofStatus.notSubmitted,
    );
  }
}

class LatLngCoordinates {
  final double latitude;
  final double longitude;

  const LatLngCoordinates({required this.latitude, required this.longitude});

  factory LatLngCoordinates.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('coordinates') && json['coordinates'] is List) {
      final list = json['coordinates'] as List;
      if (list.length >= 2) {
        return LatLngCoordinates(
          longitude: (list[0] as num).toDouble(),
          latitude: (list[1] as num).toDouble(),
        );
      }
    }
    return LatLngCoordinates(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 21.1458,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 79.0882,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class AssignedResponder {
  final String id;
  final String displayName;
  final String phone;
  final String? role;

  const AssignedResponder({
    required this.id,
    required this.displayName,
    required this.phone,
    this.role,
  });

  factory AssignedResponder.fromJson(Map<String, dynamic> json) {
    return AssignedResponder(
      id: json['id'] ?? json['_id'] ?? '',
      displayName: json['displayName'] ?? 'Volunteer Responder',
      phone: json['phone'] ?? '',
      role: json['role'],
    );
  }
}

class EmergencyModel {
  final String id;
  final String ownerId;
  final String? ownerName;
  final EmergencyCategory category;
  final EmergencyStatus status;
  final LatLngCoordinates location;
  final int? approximateDistanceMeters;
  final AssignedResponder? assignedResponder;
  final String? notes;
  final int version;
  final ProofStatus proofStatus;
  final String? transactionHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyModel({
    required this.id,
    required this.ownerId,
    this.ownerName,
    required this.category,
    required this.status,
    required this.location,
    this.approximateDistanceMeters,
    this.assignedResponder,
    this.notes,
    this.version = 1,
    this.proofStatus = ProofStatus.notSubmitted,
    this.transactionHash,
    required this.createdAt,
    required this.updatedAt,
  });

  EmergencyModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    EmergencyCategory? category,
    EmergencyStatus? status,
    LatLngCoordinates? location,
    int? approximateDistanceMeters,
    AssignedResponder? assignedResponder,
    String? notes,
    int? version,
    ProofStatus? proofStatus,
    String? transactionHash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      category: category ?? this.category,
      status: status ?? this.status,
      location: location ?? this.location,
      approximateDistanceMeters:
          approximateDistanceMeters ?? this.approximateDistanceMeters,
      assignedResponder: assignedResponder ?? this.assignedResponder,
      notes: notes ?? this.notes,
      version: version ?? this.version,
      proofStatus: proofStatus ?? this.proofStatus,
      transactionHash: transactionHash ?? this.transactionHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    final ownerMap = json['owner'];
    final ownerId = ownerMap is Map ? (ownerMap['id'] ?? '') : (json['ownerId'] ?? '');
    final ownerName = ownerMap is Map ? ownerMap['displayName'] : null;

    final assignedMap = json['assignedResponder'];
    final assigned = assignedMap is Map<String, dynamic>
        ? AssignedResponder.fromJson(assignedMap)
        : null;

    final proofMap = json['proof'] as Map<String, dynamic>?;

    return EmergencyModel(
      id: json['id'] ?? json['_id'] ?? '',
      ownerId: ownerId,
      ownerName: ownerName,
      category: EmergencyCategory.fromString(json['category'] ?? 'MEDICAL'),
      status: EmergencyStatus.fromString(json['status'] ?? 'ACTIVE'),
      location: json['location'] != null
          ? LatLngCoordinates.fromJson(json['location'])
          : const LatLngCoordinates(latitude: 21.1458, longitude: 79.0882),
      approximateDistanceMeters: json['approximateDistanceMeters'],
      assignedResponder: assigned,
      notes: json['notes'],
      version: json['version'] ?? 1,
      proofStatus: proofMap != null
          ? ProofStatus.fromString(proofMap['status'] ?? 'NOT_SUBMITTED')
          : ProofStatus.notSubmitted,
      transactionHash: proofMap?['transactionHash'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
