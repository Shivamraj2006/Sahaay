// ─── Shared Enums ───────────────────────────────────────────────────────────
// Canonical enums from 00-shared-contract.md. All layers must match exactly.

export enum Role {
  ELDERLY_USER = 'ELDERLY_USER',
  VOLUNTEER = 'VOLUNTEER',
  MEDICAL_PROFESSIONAL = 'MEDICAL_PROFESSIONAL',
  ORGANIZATION_COORDINATOR = 'ORGANIZATION_COORDINATOR',
  VERIFIER = 'VERIFIER',
  ADMIN = 'ADMIN',
}

/** Roles that users cannot self-assign during registration. */
export const PRIVILEGED_ROLES = new Set([Role.VERIFIER, Role.ADMIN]);

/** Roles eligible to be responders. */
export const RESPONDER_ROLES = new Set([
  Role.VOLUNTEER,
  Role.MEDICAL_PROFESSIONAL,
  Role.ORGANIZATION_COORDINATOR,
]);

export enum EmergencyCategory {
  MEDICAL = 'MEDICAL',
  FALL_INJURY = 'FALL_INJURY',
  HOSPITAL_ASSISTANCE = 'HOSPITAL_ASSISTANCE',
}

export enum EmergencyStatus {
  ACTIVE = 'ACTIVE',
  ASSIGNED = 'ASSIGNED',
  RESPONDER_ARRIVED = 'RESPONDER_ARRIVED',
  ESCALATED = 'ESCALATED',
  RESOLVED = 'RESOLVED',
  CANCELLED = 'CANCELLED',
}

export const TERMINAL_STATUSES = new Set([
  EmergencyStatus.RESOLVED,
  EmergencyStatus.CANCELLED,
]);

export enum VerificationStatus {
  UNVERIFIED = 'UNVERIFIED',
  PENDING = 'PENDING',
  VERIFIED = 'VERIFIED',
  REVOKED = 'REVOKED',
}

export enum ProofStatus {
  NOT_SUBMITTED = 'NOT_SUBMITTED',
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  FAILED = 'FAILED',
}

export enum ResolutionOutcome {
  ASSISTED = 'ASSISTED',
  REFERRED_TO_EMERGENCY_SERVICES = 'REFERRED_TO_EMERGENCY_SERVICES',
  NO_CONTACT = 'NO_CONTACT',
  OTHER = 'OTHER',
}

export enum SocketEvent {
  EMERGENCY_CREATED = 'emergency.created',
  EMERGENCY_UPDATED = 'emergency.updated',
  RESPONDER_ACCEPTED = 'responder.accepted',
  RESPONDER_ARRIVED = 'responder.arrived',
  EMERGENCY_RESOLVED = 'emergency.resolved',
  EMERGENCY_CANCELLED = 'emergency.cancelled',
}

export enum EmergencyEventType {
  CREATED = 'CREATED',
  CANCELLED = 'CANCELLED',
  ACCEPTED = 'ACCEPTED',
  DECLINED = 'DECLINED',
  ARRIVED = 'ARRIVED',
  ESCALATED = 'ESCALATED',
  RESOLVED = 'RESOLVED',
}

export enum VerificationAction {
  VERIFY = 'VERIFY',
  REVOKE = 'REVOKE',
}
