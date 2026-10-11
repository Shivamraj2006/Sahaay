import { describe, it, expect } from 'vitest';
import {
  EmergencyStatus,
  TERMINAL_STATUSES,
  EmergencyEventType,
} from '../src/shared/enums';
import { ConflictError } from '../src/shared/errors';

describe('Emergency State Machine & Transition Rules', () => {
  // Valid transitions defined by 00-shared-contract.md:
  // ACTIVE -> ASSIGNED (accept)
  // ACTIVE -> CANCELLED (cancel)
  // ASSIGNED -> RESPONDER_ARRIVED (arrive)
  // [ACTIVE, ASSIGNED, RESPONDER_ARRIVED] -> ESCALATED (escalate)
  // [ASSIGNED, RESPONDER_ARRIVED, ESCALATED] -> RESOLVED (resolve)

  const LEGAL_TRANSITIONS: Record<EmergencyStatus, EmergencyStatus[]> = {
    [EmergencyStatus.ACTIVE]: [
      EmergencyStatus.ASSIGNED,
      EmergencyStatus.CANCELLED,
      EmergencyStatus.ESCALATED,
    ],
    [EmergencyStatus.ASSIGNED]: [
      EmergencyStatus.RESPONDER_ARRIVED,
      EmergencyStatus.ESCALATED,
      EmergencyStatus.RESOLVED,
    ],
    [EmergencyStatus.RESPONDER_ARRIVED]: [
      EmergencyStatus.ESCALATED,
      EmergencyStatus.RESOLVED,
    ],
    [EmergencyStatus.ESCALATED]: [
      EmergencyStatus.RESOLVED,
    ],
    [EmergencyStatus.RESOLVED]: [], // Terminal
    [EmergencyStatus.CANCELLED]: [], // Terminal
  };

  it('correctly classifies terminal statuses (RESOLVED and CANCELLED)', () => {
    expect(TERMINAL_STATUSES.has(EmergencyStatus.RESOLVED)).toBe(true);
    expect(TERMINAL_STATUSES.has(EmergencyStatus.CANCELLED)).toBe(true);
    expect(TERMINAL_STATUSES.has(EmergencyStatus.ACTIVE)).toBe(false);
    expect(TERMINAL_STATUSES.has(EmergencyStatus.ASSIGNED)).toBe(false);
    expect(TERMINAL_STATUSES.has(EmergencyStatus.RESPONDER_ARRIVED)).toBe(false);
    expect(TERMINAL_STATUSES.has(EmergencyStatus.ESCALATED)).toBe(false);
  });

  it('verifies that terminal states have no legal subsequent transitions', () => {
    expect(LEGAL_TRANSITIONS[EmergencyStatus.RESOLVED]).toHaveLength(0);
    expect(LEGAL_TRANSITIONS[EmergencyStatus.CANCELLED]).toHaveLength(0);
  });

  it('allows resolution only from valid active/assigned/escalated states', () => {
    const validResolveFrom = [
      EmergencyStatus.ASSIGNED,
      EmergencyStatus.RESPONDER_ARRIVED,
      EmergencyStatus.ESCALATED,
    ];

    for (const status of validResolveFrom) {
      expect(LEGAL_TRANSITIONS[status]).toContain(EmergencyStatus.RESOLVED);
    }

    // Resolving directly from ACTIVE is not allowed (must be accepted/assigned first)
    expect(LEGAL_TRANSITIONS[EmergencyStatus.ACTIVE]).not.toContain(EmergencyStatus.RESOLVED);
  });

  it('allows cancellation only while ACTIVE', () => {
    expect(LEGAL_TRANSITIONS[EmergencyStatus.ACTIVE]).toContain(EmergencyStatus.CANCELLED);
    expect(LEGAL_TRANSITIONS[EmergencyStatus.ASSIGNED]).not.toContain(EmergencyStatus.CANCELLED);
    expect(LEGAL_TRANSITIONS[EmergencyStatus.RESPONDER_ARRIVED]).not.toContain(EmergencyStatus.CANCELLED);
  });

  it('generates appropriate ConflictError shapes for illegal transitions', () => {
    const error = new ConflictError(
      'INVALID_STATE_TRANSITION',
      `Cannot mark arrived from status '${EmergencyStatus.ACTIVE}'.`,
    );

    expect(error.statusCode).toBe(409);
    expect(error.code).toBe('INVALID_STATE_TRANSITION');
    expect(error.message).toContain(EmergencyStatus.ACTIVE);
  });
});
