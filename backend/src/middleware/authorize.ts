import { Request, Response, NextFunction } from 'express';
import { Role } from '../shared/enums';
import { ForbiddenError, UnauthorizedError } from '../shared/errors';

/**
 * Role-based authorization middleware factory.
 * Returns middleware that checks whether the authenticated user's role
 * is in the allowed set.
 */
export function authorize(...allowedRoles: Role[]) {
  const allowed = new Set(allowedRoles);

  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      return next(new UnauthorizedError());
    }

    if (!allowed.has(req.user.role)) {
      return next(new ForbiddenError());
    }

    next();
  };
}
