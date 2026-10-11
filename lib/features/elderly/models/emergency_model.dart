/// Emergency Category enum:
/// MEDICAL | FALL_INJURY | HOSPITAL_ASSISTANCE
enum EmergencyCategory {
  medical('MEDICAL', 'Medical Emergency', 'Chest pain, severe breathlessness, stroke signs'),
  fallInjury('FALL_INJURY', 'Fall / Injury', 'Slipped, unable to get up, suspected fracture'),
  hospitalAssistance('HOSPITAL_ASSISTANCE', 'Hospital Assistance', 'Urgent need to reach nearest medical facility');

  final String value;
  final String label;
  final String subtitle;
  const EmergencyCategory(this.value, this.label, this.subtitle);

  static EmergencyCategory fromString(String? cat) {
    if (cat == null) return EmergencyCategory.medical;
    for (final c in EmergencyCategory.values) {
      if (c.value.toUpperCase() == cat.toUpperCase()) return c;
    }
    return EmergencyCategory.medical;
  }
}

/// Emergency Status enum:
/// ACTIVE | ASSIGNED | RESPONDER_ARRIVED | ESCALATED | RESOLVED | CANCELLED
enum EmergencyStatus {
  active('ACTIVE'),
  assigned('ASSIGNED'),
  responderArrived('RESPONDER_ARRIVED'),
  escalated('ESCALATED'),
  resolved('RESOLVED'),
  cancelled('CANCELLED');

  final String value;
  const EmergencyStatus(this.value);

  static EmergencyStatus fromString(String? status) {
    if (status == null) return EmergencyStatus.active;
    for (final s in EmergencyStatus.values) {
      if (s.value.toUpperCase() == status.toUpperCase()) return s;
    }
    return EmergencyStatus.active;
  }

  bool get isTerminal => this == EmergencyStatus.resolved || this == EmergencyStatus.cancelled;
}

/// Proof submission status enum:
/// NOT_SUBMITTED | PENDING | CONFIRMED | FAILED
enum ProofStatus {
  notSubmitted('NOT_SUBMITTED'),
  pending('PENDING'),
  confirmed('CONFIRMED'),
  failed('FAILED');

  final String value;
  const ProofStatus(this.value);

  static ProofStatus fromString(String? status) {
    if (status == null) return ProofStatus.notSubmitted;
    for (final s in ProofStatus.values) {
      if (s.value.toUpperCase() == status.toUpperCase()) return s;
    }
    return ProofStatus.notSubmitted;
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;

  LocationPoint({required this.latitude, required this.longitude});

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

class EmergencyOwner {
  final String id;
  final String displayName;
  final String? phone;

  EmergencyOwner({required this.id, required this.displayName, this.phone});

  factory EmergencyOwner.fromJson(Map<String, dynamic> json) {
    return EmergencyOwner(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Citizen',
      phone: json['phone'] as String?,
    );
  }
}

class AssignedResponder {
  final String id;
  final String displayName;
  final String? phone;
  final String? role;

  AssignedResponder({required this.id, required this.displayName, this.phone, this.role});

  factory AssignedResponder.fromJson(Map<String, dynamic> json) {
    return AssignedResponder(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Responder',
      phone: json['phone'] as String?,
      role: json['role'] as String?,
    );
  }
}

class EscalationDetails {
  final bool isEscalated;
  final String? reason;

  EscalationDetails({required this.isEscalated, this.reason});

  factory EscalationDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return EscalationDetails(isEscalated: false);
    return EscalationDetails(
      isEscalated: json['isEscalated'] as bool? ?? false,
      reason: json['reason'] as String?,
    );
  }
}

class ProofRecord {
  final ProofStatus status;
  final String? transactionHash;

  ProofRecord({required this.status, this.transactionHash});

  factory ProofRecord.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ProofRecord(status: ProofStatus.notSubmitted);
    return ProofRecord(
      status: ProofStatus.fromString(json['status'] as String?),
      transactionHash: json['transactionHash'] as String?,
    );
  }
}

class EmergencyModel {
  final String id;
  final EmergencyCategory category;
  final EmergencyStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EmergencyOwner owner;
  final LocationPoint? location; // Nullable if coarse/approximate or omitted
  final double? approximateDistanceMeters;
  final AssignedResponder? assignedResponder;
  final EscalationDetails escalation;
  final ProofRecord proof;
  final String? notes;

  EmergencyModel({
    required this.id,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.owner,
    this.location,
    this.approximateDistanceMeters,
    this.assignedResponder,
    required this.escalation,
    required this.proof,
    this.notes,
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    return EmergencyModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      category: EmergencyCategory.fromString(json['category'] as String?),
      status: EmergencyStatus.fromString(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      owner: EmergencyOwner.fromJson(json['owner'] as Map<String, dynamic>? ?? {}),
      location: json['location'] != null
          ? LocationPoint.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      approximateDistanceMeters: (json['approximateDistanceMeters'] as num?)?.toDouble(),
      assignedResponder: json['assignedResponder'] != null
          ? AssignedResponder.fromJson(json['assignedResponder'] as Map<String, dynamic>)
          : null,
      escalation: EscalationDetails.fromJson(json['escalation'] as Map<String, dynamic>?),
      proof: ProofRecord.fromJson(json['proof'] as Map<String, dynamic>?),
      notes: json['notes'] as String?,
    );
  }
}
