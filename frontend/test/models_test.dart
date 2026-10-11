import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay_flutter/models/user.dart';
import 'package:sahaay_flutter/models/emergency.dart';
import 'package:sahaay_flutter/models/contact.dart';

void main() {
  group('Sahaay Flutter Domain Models Test Suite', () {
    test('UserRole parsing and privilege flags', () {
      expect(UserRole.fromString('ELDERLY_USER'), UserRole.elderlyUser);
      expect(UserRole.fromString('VOLUNTEER'), UserRole.volunteer);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);

      const elderlyUser = UserModel(
        id: 'u1',
        displayName: 'Kamla Devi',
        phone: '+919876543210',
        role: UserRole.elderlyUser,
      );
      expect(elderlyUser.isElderly, true);
      expect(elderlyUser.isResponder, false);

      const responder = UserModel(
        id: 'u2',
        displayName: 'Rahul Sharma',
        phone: '+919876543211',
        role: UserRole.volunteer,
      );
      expect(responder.isElderly, false);
      expect(responder.isResponder, true);
    });

    test('EmergencyCategory and EmergencyStatus enums match shared contract', () {
      expect(EmergencyCategory.fromString('MEDICAL'), EmergencyCategory.medical);
      expect(EmergencyCategory.fromString('FALL_INJURY'), EmergencyCategory.fallInjury);
      expect(EmergencyCategory.fromString('HOSPITAL_ASSISTANCE'), EmergencyCategory.hospitalAssistance);

      expect(EmergencyStatus.fromString('ACTIVE'), EmergencyStatus.active);
      expect(EmergencyStatus.fromString('ASSIGNED'), EmergencyStatus.assigned);
      expect(EmergencyStatus.fromString('RESPONDER_ARRIVED'), EmergencyStatus.responderArrived);
      expect(EmergencyStatus.fromString('RESOLVED'), EmergencyStatus.resolved);
      expect(EmergencyStatus.fromString('CANCELLED'), EmergencyStatus.cancelled);

      expect(EmergencyStatus.resolved.isTerminal, true);
      expect(EmergencyStatus.cancelled.isTerminal, true);
      expect(EmergencyStatus.active.isTerminal, false);
    });

    test('EmergencyContact default contacts match Stitch specifications', () {
      final contacts = EmergencyContact.defaultContacts();
      expect(contacts.length, 3);
      expect(contacts[0].name, 'Ramesh Kumar');
      expect(contacts[0].relationship, 'Son');
      expect(contacts[1].name, 'Lakshmi');
      expect(contacts[1].relationship, 'Daughter');
      expect(contacts[2].name, 'Dr. Meera Iyer');
      expect(contacts[2].relationship, 'Family Doctor');
    });

    test('EmergencyModel parses JSON properly with location and proof status', () {
      final json = {
        'id': 'emg_123',
        'owner': {'id': 'owner_1', 'displayName': 'Kamla Devi'},
        'category': 'FALL_INJURY',
        'status': 'ACTIVE',
        'location': {'latitude': 12.9352, 'longitude': 77.6245},
        'proof': {'status': 'NOT_SUBMITTED'},
        'version': 1,
        'createdAt': '2026-10-11T08:30:00.000Z',
      };

      final emg = EmergencyModel.fromJson(json);
      expect(emg.id, 'emg_123');
      expect(emg.ownerName, 'Kamla Devi');
      expect(emg.category, EmergencyCategory.fallInjury);
      expect(emg.status, EmergencyStatus.active);
      expect(emg.location.latitude, 12.9352);
      expect(emg.location.longitude, 77.6245);
      expect(emg.proofStatus, ProofStatus.notSubmitted);
    });
  });
}
