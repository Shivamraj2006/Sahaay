import { describe, it, expect } from 'vitest';
import crypto from 'crypto';
import {
  createCanonicalRecord,
  computeDigest,
  CanonicalProofRecord,
} from '../src/modules/trust/canonical';
import { CANONICAL_TEST_VECTORS } from '../src/modules/trust/test-vectors';
import { EmergencyEventType } from '../src/shared/enums';

describe('Canonical Proof Hashing & Test Vectors', () => {
  it('computes correct digest for all shared test vectors', () => {
    for (const vector of CANONICAL_TEST_VECTORS) {
      const computed = computeDigest(vector.record as CanonicalProofRecord);
      expect(computed).toBe(vector.expectedDigest);

      // Verify canonical JSON representation
      const sortedJson = JSON.stringify(
        vector.record,
        Object.keys(vector.record).sort(),
      );
      expect(sortedJson).toBe(vector.canonicalJson);

      // Verify that direct SHA-256 of canonical JSON matches expected digest
      const directHash = crypto
        .createHash('sha256')
        .update(sortedJson, 'utf-8')
        .digest('hex');
      expect(directHash).toBe(vector.expectedDigest);
    }
  });

  it('guarantees deterministic serialization regardless of key insertion order', () => {
    const recordA: CanonicalProofRecord = {
      schemaVersion: 1,
      proofId: 'proof123',
      emergencyRef: 'emg456',
      responderRef: 'resp789',
      eventType: EmergencyEventType.ARRIVED,
      occurredAt: '2026-10-11T12:00:00Z',
    };

    // Construct recordB with different key insertion order
    const recordB: CanonicalProofRecord = {
      occurredAt: '2026-10-11T12:00:00Z',
      eventType: EmergencyEventType.ARRIVED,
      responderRef: 'resp789',
      emergencyRef: 'emg456',
      proofId: 'proof123',
      schemaVersion: 1,
    };

    expect(computeDigest(recordA)).toBe(computeDigest(recordB));
  });

  it('produces opaque references that do not leak raw database IDs', () => {
    const rawId = '66f7a8b9c0d1e2f3a4b5c6d7';
    const record = createCanonicalRecord({
      emergencyId: rawId,
      responderId: rawId,
      eventType: EmergencyEventType.ARRIVED,
      timestamp: new Date('2026-10-11T12:00:00.000Z'),
    });

    expect(record.emergencyRef).not.toContain(rawId);
    expect(record.responderRef).not.toContain(rawId);
    expect(record.proofId).not.toContain(rawId);
    expect(record.emergencyRef.length).toBe(16);
    expect(record.occurredAt).toBe('2026-10-11T12:00:00Z');
  });

  it('normalizes timestamp by stripping milliseconds', () => {
    const dateWithMs = new Date('2026-10-11T14:23:45.678Z');
    const record = createCanonicalRecord({
      emergencyId: 'emg1',
      responderId: 'resp1',
      eventType: EmergencyEventType.RESOLVED,
      timestamp: dateWithMs,
      outcome: 'ASSISTED',
    });

    expect(record.occurredAt).toBe('2026-10-11T14:23:45Z');
    expect(record.occurredAt).not.toContain('.678');
  });
});
