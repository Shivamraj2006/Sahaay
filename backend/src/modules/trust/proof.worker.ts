import { config } from '../../config';
import { trustService } from './trust.service';
import { Emergency } from '../../models/Emergency';
import { ProofStatus } from '../../shared/enums';

const MAX_RETRIES = 5;
const WORKER_INTERVAL_MS = 30000; // 30 seconds

let workerTimer: ReturnType<typeof setInterval> | null = null;

/**
 * Simple in-process proof worker.
 *
 * Picks up NOT_SUBMITTED proofs from the outbox and attempts blockchain
 * submission. For the hackathon MVP, this runs as a setInterval loop
 * in the same process. In production, this would be a separate worker
 * or queue consumer.
 *
 * If blockchain is not configured, the worker logs and skips.
 */
export function startProofWorker() {
  if (!config.isBlockchainConfigured) {
    console.warn('[PROOF_WORKER] Blockchain not configured — worker disabled. Proofs will remain NOT_SUBMITTED.');
    return;
  }

  console.log('[PROOF_WORKER] Starting proof worker...');
  workerTimer = setInterval(processOutbox, WORKER_INTERVAL_MS);
}

export function stopProofWorker() {
  if (workerTimer) {
    clearInterval(workerTimer);
    workerTimer = null;
    console.log('[PROOF_WORKER] Worker stopped.');
  }
}

async function processOutbox() {
  try {
    const pending = await trustService.getPendingProofs(5);
    if (pending.length === 0) return;

    console.log(`[PROOF_WORKER] Processing ${pending.length} proof(s)...`);

    for (const proof of pending) {
      if (proof.retryCount >= MAX_RETRIES) {
        await trustService.markFailed(proof._id.toString(), 'MAX_RETRIES_EXCEEDED');
        continue;
      }

      try {
        const emergency = await Emergency.findById(proof.emergencyId);
        // Submit to blockchain
        const txHash = await submitToBlockchain(proof, emergency || { _id: proof.emergencyId });
        await trustService.markPending(proof._id.toString(), txHash);

        // Update emergency proof status
        await Emergency.findByIdAndUpdate(proof.emergencyId, {
          $set: {
            'proof.status': ProofStatus.PENDING,
            'proof.transactionHash': txHash,
          },
        });

        // Wait for confirmation (simplified for MVP)
        const confirmed = await waitForConfirmation(txHash);
        if (confirmed) {
          await trustService.markConfirmed(proof._id.toString());
          await Emergency.findByIdAndUpdate(proof.emergencyId, {
            $set: { 'proof.status': ProofStatus.CONFIRMED },
          });
          console.log(`[PROOF_WORKER] Proof confirmed: ${txHash}`);
        } else {
          await trustService.markFailed(proof._id.toString(), 'CONFIRMATION_TIMEOUT');
        }
      } catch (err: any) {
        console.error(`[PROOF_WORKER] Submission error for proof ${proof._id}:`, err.message);
        await trustService.markFailed(
          proof._id.toString(),
          err.code || 'SUBMISSION_ERROR',
        );
      }
    }
  } catch (err) {
    console.error('[PROOF_WORKER] Outbox processing error:', err);
  }
}

import { ethers } from 'ethers';
import { IProofOutbox } from '../../models/ProofOutbox';

// In processOutbox, we have access to proof and emergency
async function submitToBlockchain(
  proof: IProofOutbox,
  emergency: any
): Promise<string> {
  if (config.isBlockchainConfigured) {
    try {
      const provider = new ethers.JsonRpcProvider(config.blockchain.rpcUrl);
      const wallet = new ethers.Wallet(config.blockchain.privateKey, provider);
      const abi = (await import('../../contracts/EmergencyLedger.json')).default;
      const contract = new ethers.Contract(
        config.blockchain.emergencyLedgerAddress,
        abi,
        wallet
      );

      const proofIdBytes32 = ethers.id(proof._id.toString());
      const emergencyRefBytes32 = ethers.id(emergency._id.toString());
      const responderRefBytes32 = emergency.assignedResponderId
        ? ethers.id(emergency.assignedResponderId.toString())
        : ethers.id('unassigned');
      const eventTypeEnum =
        proof.eventType === 'RESOLVED' ? 1 : 0;
      const payloadHashBytes32 = '0x' + proof.digest;

      const tx = await contract.recordProof(
        proofIdBytes32,
        emergencyRefBytes32,
        responderRefBytes32,
        eventTypeEnum,
        proof.schemaVersion,
        payloadHashBytes32
      );
      return tx.hash;
    } catch (err: any) {
      console.error('[PROOF_WORKER] Contract recordProof error:', err.message);
      throw err;
    }
  }

  console.log(
    `[PROOF_WORKER] Blockchain unconfigured, simulating submission: digest=${proof.digest.substring(0, 16)}... eventType=${proof.eventType}`
  );
  const { randomBytes } = await import('crypto');
  return '0x' + randomBytes(32).toString('hex');
}

/**
 * Wait for transaction confirmation.
 */
async function waitForConfirmation(txHash: string): Promise<boolean> {
  if (config.isBlockchainConfigured) {
    try {
      const provider = new ethers.JsonRpcProvider(config.blockchain.rpcUrl);
      const receipt = await provider.waitForTransaction(txHash, 1, 30000);
      return receipt !== null && receipt.status === 1;
    } catch (err: any) {
      console.warn(`[PROOF_WORKER] Transaction confirmation error: ${err.message}`);
      return false;
    }
  }

  // Simulate confirmation for development
  await new Promise((resolve) => setTimeout(resolve, 1000));
  return true;
}
