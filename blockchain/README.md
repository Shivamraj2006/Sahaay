# Sahaay Blockchain Trust Layer

EVM-based trust and audit layer for the Sahaay community emergency-response network. Built with Solidity (`^0.8.20`), Hardhat, Ethers.js v6, and OpenZeppelin Contracts.

## Overview

The blockchain layer acts as a tamper-evident audit log for:
1. **Responder Verification Status**: Verifiers attest whether community responders are `VERIFIED` or `REVOKED`.
2. **Emergency Milestone Proofs**: Backend attestors record versioned milestones (`RESPONDER_ARRIVED`, `EMERGENCY_RESOLVED`) with canonical SHA-256 digests.

### Key Invariants & Non-Goals
- **Zero Personal Identifiable Information (PII)**: No names, phone numbers, government IDs, medical records, or coordinates are ever placed in calldata, storage, or events. Only pseudonymous `bytes32` references are used.
- **Audit Layer Only**: The blockchain is an audit ledger, not the runtime dispatch engine. Blockchain latency or RPC outages never block SOS dispatch, responder assignment, or resolution.
- **No Speculative Tokens**: No cryptocurrency payments, tradable tokens, NFTs, or DAO mechanics.

---

## Smart Contracts

### 1. `ResponderRegistry.sol`
- **Access Control**: OpenZeppelin `AccessControl` (`DEFAULT_ADMIN_ROLE`, `VERIFIER_ROLE`)
- **Status Enum**: `UNVERIFIED` (0), `VERIFIED` (1), `REVOKED` (2)
- **Functions**:
  - `setVerifier(address account, bool enabled)` — Admin manages verifiers
  - `setResponderStatus(bytes32 responderRef, VerificationStatus status)` — Verifier updates status
  - `getResponderStatus(bytes32 responderRef)` — Read current status (defaults to `UNVERIFIED`)
  - `isVerified(bytes32 responderRef)` — Helper returning boolean
- **Events**:
  - `ResponderStatusChanged(bytes32 indexed responderRef, VerificationStatus status, address indexed verifier, uint256 timestamp)`

### 2. `EmergencyLedger.sol`
- **Access Control**: OpenZeppelin `AccessControl` (`DEFAULT_ADMIN_ROLE`, `ATTESTOR_ROLE`)
- **Event Types**: `RESPONDER_ARRIVED` (0), `EMERGENCY_RESOLVED` (1)
- **Functions**:
  - `setAttestor(address account, bool enabled)` — Admin manages backend attestor accounts
  - `recordProof(bytes32 proofId, bytes32 emergencyRef, bytes32 responderRef, ProofEventType eventType, uint16 schemaVersion, bytes32 payloadHash)` — Attestor records tamper-evident milestone
  - `hasProof(bytes32 proofId)` — Checks proof existence
  - `getProof(bytes32 proofId)` — Retrieves stored proof struct
- **Invariants**: Unique `proofId` prevents replay or duplicate entries (`PROOF_ALREADY_RECORDED`).

---

## Quick Start

### Prerequisites
- Node.js 18+
- npm

### Installation & Compilation

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile
```

### Running Tests

```bash
npm test
```

Executes 22 automated tests covering:
- **Admin Access Control**: Granting and revoking roles; rejecting unauthorized accounts.
- **Verifier Lifecycle**: Setting `VERIFIED` and `REVOKED` states; validating `UNVERIFIED` default.
- **Attestor Ledger**: Milestone recording, event emissions, input validation, duplicate rejection.
- **Cross-Layer Test Vectors**: Byte-for-byte matching between backend canonical JSON hashing and on-chain `bytes32 payloadHash`.

### Deployment

```bash
# Deploy to in-memory Hardhat network (exports ABIs to backend)
npm run deploy:hardhat

# Deploy to a running local node (http://127.0.0.1:8545)
npm run deploy:local
```

Deployment automatically:
1. Deploys `ResponderRegistry` and `EmergencyLedger`.
2. Grants `VERIFIER_ROLE` and `ATTESTOR_ROLE` to configured addresses.
3. Exports contract ABIs and addresses directly to `backend/src/contracts/`.
4. Saves deployment metadata to `blockchain/deployments/<network>.json`.

---

## Canonical Proof Hashing Specification

Cross-layer proof records follow a frozen JSON schema with sorted keys, UTF-8 encoding, and ISO 8601 UTC timestamps without milliseconds:

```json
{
  "emergencyRef": "8f6828b1e4277b94",
  "eventType": "ARRIVED",
  "occurredAt": "2026-10-11T08:30:00Z",
  "proofId": "e9f50cb90e7a1e0b",
  "responderRef": "a52e25fa9e4210bc",
  "schemaVersion": 1
}
```

- **Algorithm**: `SHA-256` over the sorted JSON string.
- **Solidity Parameter**: The 32-byte hex string is passed directly as `bytes32 payloadHash`.
- **Test Vectors**: Validated in `test/CrossLayerTestVectors.test.ts` and `backend/tests/canonical.test.ts`.

---

## Directory Structure

```
blockchain/
├── contracts/
│   ├── EmergencyLedger.sol      # Milestone proof audit ledger
│   └── ResponderRegistry.sol    # Responder verification registry
├── scripts/
│   └── deploy.ts                # Deployment & role configuration script
├── test/
│   ├── CrossLayerTestVectors.test.ts
│   ├── EmergencyLedger.test.ts
│   └── ResponderRegistry.test.ts
├── deployments/                 # Deployment records
├── hardhat.config.ts            # Hardhat configuration
├── package.json
└── tsconfig.json
```

---

## Known Trust Assumptions

1. **Attestor Trust**: The ledger proves that an authorized backend account recorded an event at a given block time; it does not replace off-chain corroboration.
2. **Off-Chain Operational Authority**: Operational dispatch remains in the backend database to avoid blocking life-safety workflows on blockchain confirmation times.
3. **Public Services**: Sahaay coordinates community responders and complements public emergency services; it does not contact 112/108 automatically.
