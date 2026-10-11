import crypto from 'crypto';
import { EmergencyEventType } from '../../shared/enums';

/** Schema version for canonical proof records. */
const PROOF_SCHEMA_VERSION = 1;

/**
 * Canonical proof record for tamper-evident hashing.
 *
 * Fixed key order, no sensitive fields, normalized timestamps,
 * UTF-8 JSON encoding. This format is shared with the blockchain agent
 * for cross-layer verification.
 */
export interface CanonicalProofRecord {
  schemaVersion: number;
  proofId: string;
  emergencyRef: string;
  responderRef: string;
  eventType: EmergencyEventType;
  occurredAt: string; // ISO 8601 UTC, no milliseconds
  outcome?: string;
}

/**
 * Create a canonical proof record with deterministic field order.
 */
export function createCanonicalRecord(params: {
  emergencyId: string;
  responderId: string;
  eventType: EmergencyEventType;
  timestamp: Date;
  outcome?: string;
}): CanonicalProofRecord {
  // Use opaque refs derived from IDs — never raw database IDs
  const emergencyRef = deriveOpaqueRef('emergency', params.emergencyId);
  const responderRef = deriveOpaqueRef('responder', params.responderId);
  const proofId = deriveOpaqueRef('proof', `${params.emergencyId}:${params.eventType}`);

  const record: CanonicalProofRecord = {
    schemaVersion: PROOF_SCHEMA_VERSION,
    proofId,
    emergencyRef,
    responderRef,
    eventType: params.eventType,
    occurredAt: normalizeTimestamp(params.timestamp),
  };

  if (params.outcome) {
    record.outcome = params.outcome;
  }

  return record;
}

/**
 * Compute SHA-256 digest of a canonical proof record.
 * Uses JSON.stringify with sorted keys and no whitespace.
 */
export function computeDigest(record: CanonicalProofRecord): string {
  // Sort keys explicitly for deterministic serialization
  const sorted = JSON.stringify(record, Object.keys(record).sort());
  return crypto.createHash('sha256').update(sorted, 'utf-8').digest('hex');
}

/**
 * Derive an opaque, non-reversible reference from a database ID.
 * This prevents leaking internal IDs on-chain.
 */
function deriveOpaqueRef(prefix: string, id: string): string {
  return crypto
    .createHash('sha256')
    .update(`${prefix}:${id}`, 'utf-8')
    .digest('hex')
    .substring(0, 16);
}

/**
 * Normalize timestamp to ISO 8601 UTC without milliseconds.
 */
function normalizeTimestamp(date: Date): string {
  return date.toISOString().replace(/\.\d{3}Z$/, 'Z');
}
