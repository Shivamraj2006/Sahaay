import { IEmergency } from '../../models/Emergency';
import { ProofOutbox } from '../../models/ProofOutbox';
import { EmergencyEventType, ProofStatus } from '../../shared/enums';
import { createCanonicalRecord, computeDigest } from './canonical';

/**
 * Trust service: manages the proof outbox for asynchronous blockchain submission.
 *
 * The emergency write MUST commit before proof submission is attempted.
 * Blockchain failure never blocks the emergency workflow.
 */
export class TrustService {
  /**
   * Enqueue a proof for later blockchain submission.
   * Creates a canonical record, computes its digest, and stores it in the outbox.
   */
  async enqueueProof(emergency: IEmergency, eventType: EmergencyEventType) {
    const record = createCanonicalRecord({
      emergencyId: emergency._id.toString(),
      responderId: emergency.assignedResponderId?.toString() || 'none',
      eventType,
      timestamp: new Date(),
      outcome: emergency.resolution?.outcome || undefined,
    });

    const digest = computeDigest(record);

    try {
      await ProofOutbox.create({
        emergencyId: emergency._id,
        eventType,
        schemaVersion: 1,
        digest,
        proofStatus: ProofStatus.NOT_SUBMITTED,
      });
    } catch (err: any) {
      // Unique constraint violation — proof already enqueued (idempotent)
      if (err.code === 11000) {
        console.warn(`[TRUST] Proof already enqueued for ${emergency._id}/${eventType}`);
        return;
      }
      throw err;
    }
  }

  /**
   * Get all pending (unsubmitted) proofs for processing by the worker.
   */
  async getPendingProofs(limit = 10) {
    return ProofOutbox.find({
      proofStatus: ProofStatus.NOT_SUBMITTED,
    })
      .sort({ createdAt: 1 })
      .limit(limit);
  }

  /**
   * Mark a proof as pending submission with a transaction hash.
   */
  async markPending(proofId: string, transactionHash: string) {
    await ProofOutbox.findByIdAndUpdate(proofId, {
      $set: {
        proofStatus: ProofStatus.PENDING,
        transactionHash,
        lastAttemptAt: new Date(),
      },
      $inc: { retryCount: 1 },
    });
  }

  /**
   * Mark a proof as confirmed after on-chain receipt.
   */
  async markConfirmed(proofId: string) {
    await ProofOutbox.findByIdAndUpdate(proofId, {
      $set: {
        proofStatus: ProofStatus.CONFIRMED,
        confirmedAt: new Date(),
      },
    });
  }

  /**
   * Mark a proof as failed with a safe failure code.
   */
  async markFailed(proofId: string, failureCode: string) {
    await ProofOutbox.findByIdAndUpdate(proofId, {
      $set: {
        proofStatus: ProofStatus.FAILED,
        failureCode,
        lastAttemptAt: new Date(),
      },
      $inc: { retryCount: 1 },
    });
  }
}

export const trustService = new TrustService();
