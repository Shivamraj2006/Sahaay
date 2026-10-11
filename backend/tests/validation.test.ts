import { describe, it, expect } from 'vitest';
import {
  createEmergencySchema,
  resolveEmergencySchema,
  escalateEmergencySchema,
} from '../src/modules/emergencies/emergencies.validation';
import { registerSchema, loginSchema } from '../src/modules/auth/auth.validation';
import { updateAvailabilitySchema } from '../src/modules/responders/responders.validation';
import {
  verifyResponderSchema,
  revokeResponderSchema,
} from '../src/modules/admin/admin.validation';
import {
  EmergencyCategory,
  ResolutionOutcome,
  Role,
  PRIVILEGED_ROLES,
} from '../src/shared/enums';

describe('Validation Layer (Zod Schemas)', () => {
  describe('Emergency Validation', () => {
    it('validates a correct emergency creation payload', () => {
      const valid = {
        category: EmergencyCategory.FALL_INJURY,
        location: { latitude: 21.1458, longitude: 79.0882 },
        notes: 'Elderly person slipped in living room',
      };
      const result = createEmergencySchema.safeParse(valid);
      expect(result.success).toBe(true);
    });

    it('rejects an invalid emergency category', () => {
      const invalid = {
        category: 'FIRE_ALARM',
        location: { latitude: 21.1458, longitude: 79.0882 },
      };
      const result = createEmergencySchema.safeParse(invalid);
      expect(result.success).toBe(false);
    });

    it('rejects out-of-range coordinates', () => {
      // Latitude > 90
      const invalidLat = createEmergencySchema.safeParse({
        category: EmergencyCategory.MEDICAL,
        location: { latitude: 95.0, longitude: 79.0882 },
      });
      expect(invalidLat.success).toBe(false);

      // Longitude > 180
      const invalidLng = createEmergencySchema.safeParse({
        category: EmergencyCategory.MEDICAL,
        location: { latitude: 21.1458, longitude: 185.0 },
      });
      expect(invalidLng.success).toBe(false);

      // Latitude < -90
      const invalidNegLat = createEmergencySchema.safeParse({
        category: EmergencyCategory.MEDICAL,
        location: { latitude: -95.0, longitude: 79.0882 },
      });
      expect(invalidNegLat.success).toBe(false);
    });

    it('validates emergency resolution with documented outcomes', () => {
      const valid = {
        outcome: ResolutionOutcome.ASSISTED,
        note: 'First aid rendered successfully',
      };
      expect(resolveEmergencySchema.safeParse(valid).success).toBe(true);

      const invalid = { outcome: 'UNKNOWN_OUTCOME' };
      expect(resolveEmergencySchema.safeParse(invalid).success).toBe(false);
    });

    it('requires a non-empty reason for escalation', () => {
      const empty = { reason: '' };
      expect(escalateEmergencySchema.safeParse(empty).success).toBe(false);

      const valid = { reason: 'Patient requires ambulance and oxygen support' };
      expect(escalateEmergencySchema.safeParse(valid).success).toBe(true);
    });
  });

  describe('Auth Validation', () => {
    it('accepts valid registration input', () => {
      const valid = {
        displayName: 'Kamla Devi',
        phone: '+919876543210',
        password: 'password123',
        requestedRole: Role.ELDERLY_USER,
      };
      expect(registerSchema.safeParse(valid).success).toBe(true);
    });

    it('rejects passwords shorter than 8 characters', () => {
      const invalid = {
        displayName: 'Kamla Devi',
        phone: '+919876543210',
        password: 'short',
        requestedRole: Role.ELDERLY_USER,
      };
      expect(registerSchema.safeParse(invalid).success).toBe(false);
    });

    it('identifies privileged roles that cannot be self-assigned', () => {
      expect(PRIVILEGED_ROLES.has(Role.ADMIN)).toBe(true);
      expect(PRIVILEGED_ROLES.has(Role.VERIFIER)).toBe(true);
      expect(PRIVILEGED_ROLES.has(Role.ELDERLY_USER)).toBe(false);
      expect(PRIVILEGED_ROLES.has(Role.VOLUNTEER)).toBe(false);
    });

    it('validates login credentials schema', () => {
      expect(loginSchema.safeParse({ phone: '+919876543210', password: 'password123' }).success).toBe(true);
      expect(loginSchema.safeParse({ phone: '', password: 'password123' }).success).toBe(false);
      expect(loginSchema.safeParse({ phone: '+919876543210', password: '' }).success).toBe(false);
    });
  });

  describe('Responder & Admin Validation', () => {
    it('validates availability update with optional location', () => {
      const withLoc = {
        available: true,
        location: { latitude: 21.1458, longitude: 79.0882 },
      };
      expect(updateAvailabilitySchema.safeParse(withLoc).success).toBe(true);

      const withoutLoc = { available: false };
      expect(updateAvailabilitySchema.safeParse(withoutLoc).success).toBe(true);

      const missingAvailable = { location: { latitude: 21.1458, longitude: 79.0882 } };
      expect(updateAvailabilitySchema.safeParse(missingAvailable).success).toBe(false);
    });

    it('requires a reason when revoking responder verification', () => {
      const validRevoke = { reason: 'Failed background credential verification' };
      expect(revokeResponderSchema.safeParse(validRevoke).success).toBe(true);

      const emptyRevoke = { reason: '' };
      expect(revokeResponderSchema.safeParse(emptyRevoke).success).toBe(false);
    });
  });
});
