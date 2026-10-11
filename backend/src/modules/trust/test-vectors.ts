/**
 * Canonical test vectors for cross-layer verification between backend and blockchain.
 * Both backend and Solidity test suites must verify these vectors byte-for-byte.
 *
 * Algorithm: SHA-256 over JSON with sorted keys and no insignificant whitespace.
 * Timestamps: ISO 8601 UTC with no milliseconds (ending in 'Z').
 */

export interface CanonicalTestVector {
  description: string;
  record: {
    schemaVersion: number;
    proofId: string;
    emergencyRef: string;
    responderRef: string;
    eventType: string;
    occurredAt: string;
    outcome?: string;
  };
  canonicalJson: string;
  expectedDigest: string; // SHA-256 hex
}

export const CANONICAL_TEST_VECTORS: CanonicalTestVector[] = [
  {
    description: 'Vector 1: Responder arrived event without outcome',
    record: {
      schemaVersion: 1,
      proofId: 'e9f50cb90e7a1e0b',
      emergencyRef: '8f6828b1e4277b94',
      responderRef: 'a52e25fa9e4210bc',
      eventType: 'ARRIVED',
      occurredAt: '2026-10-11T08:30:00Z',
    },
    canonicalJson: '{"emergencyRef":"8f6828b1e4277b94","eventType":"ARRIVED","occurredAt":"2026-10-11T08:30:00Z","proofId":"e9f50cb90e7a1e0b","responderRef":"a52e25fa9e4210bc","schemaVersion":1}',
    expectedDigest: 'fc51fa0c305722c7df633eb469c789d82377844d7c953f9e7ec913903f25bd6e',
  },
  {
    description: 'Vector 2: Emergency resolved event with ASSISTED outcome',
    record: {
      schemaVersion: 1,
      proofId: '7c11f42d8a55e109',
      emergencyRef: '8f6828b1e4277b94',
      responderRef: 'a52e25fa9e4210bc',
      eventType: 'RESOLVED',
      occurredAt: '2026-10-11T08:45:00Z',
      outcome: 'ASSISTED',
    },
    canonicalJson: '{"emergencyRef":"8f6828b1e4277b94","eventType":"RESOLVED","occurredAt":"2026-10-11T08:45:00Z","outcome":"ASSISTED","proofId":"7c11f42d8a55e109","responderRef":"a52e25fa9e4210bc","schemaVersion":1}',
    expectedDigest: 'bbfa86f776e82df9bc0044bb781d2cc5bb4935c7c1aac23abca1c51ec56d257f',
  },
  {
    description: 'Vector 3: Emergency resolved with REFERRED_TO_EMERGENCY_SERVICES',
    record: {
      schemaVersion: 1,
      proofId: '1b9a2c3d4e5f6071',
      emergencyRef: '3e4f5a6b7c8d9e0f',
      responderRef: 'f0e1d2c3b4a59687',
      eventType: 'RESOLVED',
      occurredAt: '2026-10-11T09:15:30Z',
      outcome: 'REFERRED_TO_EMERGENCY_SERVICES',
    },
    canonicalJson: '{"emergencyRef":"3e4f5a6b7c8d9e0f","eventType":"RESOLVED","occurredAt":"2026-10-11T09:15:30Z","outcome":"REFERRED_TO_EMERGENCY_SERVICES","proofId":"1b9a2c3d4e5f6071","responderRef":"f0e1d2c3b4a59687","schemaVersion":1}',
    expectedDigest: 'f9716dd6c2b72cd61a71bb46ec73e76340a5cd0a53f727f033a4783435418460',
  },
];
