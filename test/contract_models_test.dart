import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay_frontend/features/auth/models/user_model.dart';
import 'package:sahaay_frontend/features/elderly/models/emergency_model.dart';

void main() {
  group('Sahaay Contract Model & Enum Tests', () {
    test('UserRole and VerificationStatus parsing and role checks', () {
      expect(UserRole.fromString('ELDERLY_USER'), UserRole.elderlyUser);
      expect(UserRole.fromString('VOLUNTEER'), UserRole.volunteer);
      expect(UserRole.fromString('MEDICAL_PROFESSIONAL'), UserRole.medicalProfessional);
      expect(UserRole.fromString('VERIFIER'), UserRole.verifier);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('UNKNOWN_FALLBACK'), UserRole.elderlyUser);

      expect(UserRole.volunteer.isResponder, isTrue);
      expect(UserRole.medicalProfessional.isResponder, isTrue);
      expect(UserRole.elderlyUser.isResponder, isFalse);
      expect(UserRole.verifier.isAdminOrVerifier, isTrue);
      expect(UserRole.admin.isAdminOrVerifier, isTrue);

      expect(VerificationStatus.fromString('VERIFIED'), VerificationStatus.verified);
      expect(VerificationStatus.fromString('UNVERIFIED'), VerificationStatus.unverified);
      expect(VerificationStatus.fromString('PENDING'), VerificationStatus.pending);
      expect(VerificationStatus.fromString('REVOKED'), VerificationStatus.revoked);
    });

    test('EmergencyModel serializes and parses server contract payload accurately', () {
      final mockJson = {
        'id': 'em-test-101',
        'category': 'FALL_INJURY',
        'status': 'ACTIVE',
        'createdAt': '2026-10-11T08:30:00.000Z',
        'updatedAt': '2026-10-11T08:30:00.000Z',
        'owner': {
          'id': 'user-1',
          'displayName': 'Dada Ramkrishna',
        },
        'location': {
          'latitude': 21.1458,
          'longitude': 79.0882,
        },
        'approximateDistanceMeters': 450.0,
        'assignedResponder': null,
        'escalation': {
          'isEscalated': false,
          'reason': null,
        },
        'proof': {
          'status': 'NOT_SUBMITTED',
          'transactionHash': null,
        },
        'notes': 'Slipped near front door',
      };

      final emergency = EmergencyModel.fromJson(mockJson);
      expect(emergency.id, 'em-test-101');
      expect(emergency.category, EmergencyCategory.fallInjury);
      expect(emergency.status, EmergencyStatus.active);
      expect(emergency.owner.displayName, 'Dada Ramkrishna');
      expect(emergency.location?.latitude, 21.1458);
      expect(emergency.location?.longitude, 79.0882);
      expect(emergency.approximateDistanceMeters, 450.0);
      expect(emergency.assignedResponder, isNull);
      expect(emergency.escalation.isEscalated, isFalse);
      expect(emergency.proof.status, ProofStatus.notSubmitted);
      expect(emergency.notes, 'Slipped near front door');
    });

    test('Assigned responder payload parsing with exact coordinates', () {
      final mockAssignedJson = {
        'id': 'em-test-102',
        'category': 'MEDICAL',
        'status': 'ASSIGNED',
        'createdAt': '2026-10-11T08:30:00.000Z',
        'updatedAt': '2026-10-11T08:32:00.000Z',
        'owner': {
          'id': 'user-1',
          'displayName': 'Dada Ramkrishna',
          'phone': '+919876543210',
        },
        'location': {
          'latitude': 21.1458,
          'longitude': 79.0882,
        },
        'assignedResponder': {
          'id': 'resp-1',
          'displayName': 'Aarav Sharma',
          'phone': '+919876543211',
          'role': 'VOLUNTEER',
        },
        'escalation': {'isEscalated': false},
        'proof': {'status': 'PENDING', 'transactionHash': '0xabc123'},
      };

      final emergency = EmergencyModel.fromJson(mockAssignedJson);
      expect(emergency.status, EmergencyStatus.assigned);
      expect(emergency.assignedResponder, isNotNull);
      expect(emergency.assignedResponder!.displayName, 'Aarav Sharma');
      expect(emergency.assignedResponder!.phone, '+919876543211');
      expect(emergency.proof.status, ProofStatus.pending);
      expect(emergency.proof.transactionHash, '0xabc123');
    });
  });
}
