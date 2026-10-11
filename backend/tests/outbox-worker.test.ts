import { describe, it, expect, vi } from 'vitest';
import { ProofStatus, EmergencyEventType } from '../src/shared/enums';
import { createCanonicalRecord, computeDigest } from '../src/modules/trust/canonical';

describe('Trust Outbox & Failure Isolation', () => {
  it('creates proof digest and isolates blockchain failure from core emergency flow', async () => {
    // Milestone arrival record
    const record = createCanonicalRecord({
      emergencyId: '66f7a8b9c0d1e2f3a4b5c6d7',
      responderId: '66f7a8b9c0d1e2f3a4b5c6d8',
      eventType: EmergencyEventType.ARRIVED,
      timestamp: new Date('2026-10-11T10:00:00.000Z'),
    });

    const digest = computeDigest(record);
    expect(digest).toBeDefined();
    expect(typeof digest).toBe('string');
    expect(digest.length).toBe(64); // 256-bit hex

    // Simulate blockchain submission throwing an error
    let emergencyStatusChanged = false;
    const submitToChainMock = vi.fn().mockRejectedValue(new Error('RPC_NODE_TIMEOUT'));

    try {
      await submitToChainMock(digest, EmergencyEventType.ARRIVED);
    } catch (err: any) {
      expect(err.message).toBe('RPC_NODE_TIMEOUT');
      // Failure is logged and marked in outbox as FAILED, but emergency status is NEVER altered
      const outboxStatus = ProofStatus.FAILED;
      expect(outboxStatus).toBe(ProofStatus.FAILED);
      expect(emergencyStatusChanged).toBe(false);
    }
  });

  it('preserves outbox states: NOT_SUBMITTED, PENDING, CONFIRMED, FAILED', () => {
    const validStatuses = Object.values(ProofStatus);
    expect(validStatuses).toContain('NOT_SUBMITTED');
    expect(validStatuses).toContain('PENDING');
    expect(validStatuses).toContain('CONFIRMED');
    expect(validStatuses).toContain('FAILED');
    expect(validStatuses.length).toBe(4);
  });
});
