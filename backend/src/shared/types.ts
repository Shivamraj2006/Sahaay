import { Role } from './enums';

/** Coordinate pair for API objects. */
export interface LatLng {
  latitude: number;
  longitude: number;
}

/** Authenticated user payload injected by auth middleware. */
export interface AuthUser {
  userId: string;
  role: Role;
  isGuest?: boolean;
}

/** Extend Express Request to carry authenticated user. */
declare global {
  namespace Express {
    interface Request {
      /** Set by auth middleware after JWT verification. */
      user?: AuthUser;
      /** Correlation / request ID for structured logging. */
      requestId?: string;
    }
  }
}
