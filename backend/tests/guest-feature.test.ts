import { describe, it, expect, vi } from 'vitest';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../src/app';
import { config } from '../src/config';
import { authorize } from '../src/middleware/authorize';
import { emergencyService } from '../src/modules/emergencies/emergencies.service';
import { guestLoginSchema } from '../src/modules/auth/auth.validation';
import { createGuestEmergencySchema } from '../src/modules/emergencies/emergencies.validation';
import { EmergencyCategory, Role } from '../src/shared/enums';
import { ForbiddenError } from '../src/shared/errors';
import { AuthUser } from '../src/shared/types';

describe('Guest User & Bypass Route Feature', () => {
  const app = createApp();

  describe('Validation Schemas', () => {
    it('validates empty and filled guest login payloads', () => {
      const emptyResult = guestLoginSchema.safeParse({});
      expect(emptyResult.success).toBe(true);

      const withData = guestLoginSchema.safeParse({
        displayName: 'Elderly Visitor',
        deviceId: 'device-abc-123',
      });
      expect(withData.success).toBe(true);
    });

    it('validates guest emergency creation payload with optional contactPhone', () => {
      const valid = {
        category: EmergencyCategory.MEDICAL,
        location: { latitude: 19.076, longitude: 72.8777 },
        notes: 'Elderly person breathing difficulty',
        displayName: 'Guest Relative',
        contactPhone: '+919876543210',
      };
      const result = createGuestEmergencySchema.safeParse(valid);
      expect(result.success).toBe(true);
    });

    it('rejects guest emergency with invalid coordinates', () => {
      const invalid = {
        category: EmergencyCategory.FALL_INJURY,
        location: { latitude: 95.0, longitude: 72.8777 },
      };
      const result = createGuestEmergencySchema.safeParse(invalid);
      expect(result.success).toBe(false);
    });
  });

  describe('Authorization Security: Guest strictly blocked from Responder routes', () => {
    it('authorize middleware rejects guest users even if role matches with ForbiddenError', () => {
      const middleware = authorize(Role.VOLUNTEER, Role.ELDERLY_USER);
      const req: any = {
        user: { userId: 'guest-1', role: Role.ELDERLY_USER, isGuest: true },
      };
      const res: any = {};
      const next = vi.fn();

      middleware(req, res, next);
      expect(next).toHaveBeenCalled();
      const err = next.mock.calls[0][0];
      expect(err).toBeInstanceOf(ForbiddenError);
      expect(err.statusCode).toBe(403);
      expect(err.message).toContain('Guest users are not authorized');
    });

    it('emergencyService responder methods reject guest users', async () => {
      const guestUser: AuthUser = {
        userId: 'guest-123',
        role: Role.ELDERLY_USER,
        isGuest: true,
      };

      await expect(emergencyService.getNearby(guestUser)).rejects.toThrow(ForbiddenError);
      await expect(emergencyService.accept(guestUser, 'em-1')).rejects.toThrow(ForbiddenError);
      await expect(emergencyService.decline(guestUser, 'em-1')).rejects.toThrow(ForbiddenError);
      await expect(emergencyService.arrive(guestUser, 'em-1')).rejects.toThrow(ForbiddenError);
      await expect(
        emergencyService.resolve(guestUser, 'em-1', {
          outcome: 'ASSISTED' as any,
          note: 'Done',
        }),
      ).rejects.toThrow(ForbiddenError);
    });
  });

  describe('HTTP Endpoints & Guest Token Verification', () => {
    it('blocks access to responder routes with 403 when using guest token', async () => {
      const guestToken = jwt.sign(
        { userId: 'guest-999', role: Role.ELDERLY_USER, isGuest: true },
        config.jwt.secret,
        { expiresIn: '1h' },
      );

      const res = await request(app)
        .get('/api/v1/responders/me')
        .set('Authorization', `Bearer ${guestToken}`);

      expect(res.status).toBe(403);
      expect(res.body.error).toBeDefined();
      expect(res.body.error.code).toBe('FORBIDDEN');
    });

    it('POST /api/v1/emergencies/guest validates payload without requiring Authorization header', async () => {
      // Calling with invalid payload verifies it passes through auth without 401
      const res = await request(app)
        .post('/api/v1/emergencies/guest')
        .send({ invalid: 'body' });

      // Should fail validation (400) NOT authentication (401)
      expect(res.status).toBe(400);
      expect(res.body.error).toBeDefined();
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('POST /api/v1/emergencies without auth returns 401, confirming only /guest bypasses', async () => {
      const res = await request(app)
        .post('/api/v1/emergencies')
        .send({
          category: EmergencyCategory.MEDICAL,
          location: { latitude: 19.076, longitude: 72.8777 },
        });

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });
  });
});
