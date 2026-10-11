import { describe, it, expect, vi } from 'vitest';
import jwt from 'jsonwebtoken';
import { config } from '../src/config';
import { authenticate } from '../src/middleware/auth';
import { authorize } from '../src/middleware/authorize';
import { Role } from '../src/shared/enums';
import { UnauthorizedError, ForbiddenError } from '../src/shared/errors';

describe('Auth & Authorization Middleware', () => {
  const secret = config.jwt.secret;

  it('successfully extracts user from a valid JWT Bearer header', async () => {
    const payload = { userId: 'user-123', role: Role.ELDERLY_USER };
    const token = jwt.sign(payload, secret, { expiresIn: '1h' });

    const req: any = {
      headers: {
        authorization: `Bearer ${token}`,
      },
    };
    const res: any = {};
    const next = vi.fn();

    await authenticate(req, res, next);

    expect(next).toHaveBeenCalledWith();
    expect(req.user).toBeDefined();
    expect(req.user.userId).toBe('user-123');
    expect(req.user.role).toBe(Role.ELDERLY_USER);
  });

  it('rejects missing Authorization header with UnauthorizedError', async () => {
    const req: any = { headers: {} };
    const res: any = {};
    const next = vi.fn();

    await authenticate(req, res, next);

    expect(next).toHaveBeenCalled();
    const error = next.mock.calls[0][0];
    expect(error).toBeInstanceOf(UnauthorizedError);
    expect(error.code).toBe('UNAUTHORIZED');
  });

  it('rejects malformed or expired JWT token', async () => {
    const req: any = {
      headers: { authorization: 'Bearer invalid.token.value' },
    };
    const res: any = {};
    const next = vi.fn();

    await authenticate(req, res, next);

    expect(next).toHaveBeenCalled();
    const error = next.mock.calls[0][0];
    expect(error).toBeInstanceOf(UnauthorizedError);
  });

  it('authorize middleware permits users with matching roles', () => {
    const middleware = authorize(Role.VOLUNTEER, Role.MEDICAL_PROFESSIONAL);

    const req: any = {
      user: { userId: 'resp-1', role: Role.VOLUNTEER },
    };
    const res: any = {};
    const next = vi.fn();

    middleware(req, res, next);
    expect(next).toHaveBeenCalledWith();
  });

  it('authorize middleware blocks users without matching roles with ForbiddenError', () => {
    const middleware = authorize(Role.ADMIN);

    const req: any = {
      user: { userId: 'elder-1', role: Role.ELDERLY_USER },
    };
    const res: any = {};
    const next = vi.fn();

    middleware(req, res, next);
    expect(next).toHaveBeenCalled();
    const error = next.mock.calls[0][0];
    expect(error).toBeInstanceOf(ForbiddenError);
    expect(error.statusCode).toBe(403);
  });
});
