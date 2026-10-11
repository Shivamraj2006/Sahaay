# Sahaay — Blockchain / Solidity Handoff

**Audience:** Solidity/blockchain coding agent. Read `00-shared-contract.md` first; it is authoritative.

## 1. Purpose and non-goals

Build a small EVM trust/audit layer for Sahaay. It records authorized responder verification attestations and selected emergency milestones as tamper-evident proofs. It is not the dispatch engine, user database, emergency state machine, notification service, or source of exact location data.

Non-goals for the hackathon MVP: cryptocurrency payments, token incentives, NFTs, DAO governance, on-chain chat, on-chain health records, or putting every application event on-chain.

Important limitation: an on-chain transaction proves that an authorized account submitted a claim, not that the claimed rescue definitely happened. Real-world truth requires a trustworthy verifier/attestor and may need corroboration, review, and a dispute process.

## 2. Suggested design

Use Solidity, Hardhat, Ethers.js, and a local EVM network for deterministic tests; deploy to a testnet only if RPC/account configuration is available. Keep contracts small, testable, and access-controlled.

Possible contracts (combining is acceptable if the interface remains clear):

### `ResponderRegistry`

Responsibilities:
- Allow an administrator to grant/revoke verifier or attestor roles.
- Allow authorized verifiers to mark an opaque responder reference as verified or revoked.
- Emit events with opaque responder reference, new status, timestamp/block context, and verifier address.
- Prevent unauthorized verification/revocation.
- Do not store names, phone numbers, government IDs, documents, or detailed reasons.

Possible interface (names may vary; publish final ABI):

```solidity
enum VerificationStatus { UNVERIFIED, VERIFIED, REVOKED }
function setVerifier(address account, bool enabled) external;
function setResponderStatus(bytes32 responderRef, VerificationStatus status) external;
function getResponderStatus(bytes32 responderRef) external view returns (VerificationStatus);
event ResponderStatusChanged(bytes32 indexed responderRef, VerificationStatus status, address indexed verifier);
```

`PENDING` can remain an off-chain application state; the chain only needs to attest approved/revoked status if that is the simplest design.

### `EmergencyLedger`

Responsibilities:
- Accept proof records from an authorized backend attestor only.
- Include an opaque emergency reference, opaque responder reference, fixed event type, schema version, and canonical payload hash.
- Prevent duplicate proof IDs or duplicate `(emergencyRef, eventType, version)` records as specified.
- Emit a compact event suitable for later audit.
- Do not store exact coordinates or personal details.

Example conceptual interface:

```solidity
enum ProofEventType { RESPONDER_ARRIVED, EMERGENCY_RESOLVED }
function recordProof(
    bytes32 proofId,
    bytes32 emergencyRef,
    bytes32 responderRef,
    ProofEventType eventType,
    uint16 schemaVersion,
    bytes32 payloadHash
) external;

event ProofRecorded(
    bytes32 indexed proofId,
    bytes32 indexed emergencyRef,
    bytes32 indexed responderRef,
    ProofEventType eventType,
    uint16 schemaVersion,
    bytes32 payloadHash,
    address attestor
);
```

`proofId` must be stable and unique. Define whether repeat milestone submissions are rejected or represented by a new version. Do not silently overwrite historical proof records.

### `Reputation` (optional/separable)

For MVP, reputation can remain off-chain and be derived from confirmed/attested events. If implementing an on-chain reputation contract, keep it minimal: update counters/attestations only via an authorized backend/verifier and emit evidence. Do not introduce a financial token or claim that a score independently verifies safety or professional competence. Do not allow users to inflate their own score.

## 3. Identity and pseudonymous references

Use opaque, random identifiers that have no semantic content. Never use phone numbers, usernames, emails, MongoDB IDs that are linkable to personal identity, location coordinates, or other sensitive values directly on-chain. If the backend maps internal IDs to chain references, the mapping stays private/off-chain.

Use a documented deterministic conversion for references (for example, fixed-width `bytes32` identifiers generated from cryptographically random application IDs). Do not independently derive references differently in the backend and contract client.

## 4. Canonical hash contract with backend

This is a cross-layer integration point and must be agreed before either side finalizes implementation. Publish a shared hashing specification and at least three test vectors.

Recommended fields for a versioned record:

```json
{
  "schemaVersion": 1,
  "proofId": "opaque-proof-id",
  "emergencyRef": "opaque-emergency-ref",
  "responderRef": "opaque-responder-ref",
  "eventType": "RESPONDER_ARRIVED",
  "occurredAt": "2026-10-11T08:30:00.000Z"
}
```

This record must not include the user's identity, contact information, exact coordinates, clinical data, free-form medical notes, authentication information, or other private payload. Specify a canonical serialization exactly—for example, fixed key order, UTF-8, no insignificant whitespace, normalized UTC timestamps, and an explicitly named digest algorithm. Never hash arbitrary object serialization whose order can vary. Avoid ambiguous concatenation of fields.

If SHA-256 is used off-chain, treat the resulting 32 bytes as `bytes32` for Solidity. Ensure Ethers.js sends exactly those bytes; do not silently switch to `keccak256` in one layer. If you choose keccak256 instead, change the shared specification and tests before implementation.

Test vectors must include the canonical input string/bytes and expected digest, and should be consumed by both the backend and blockchain tests.

## 5. Security requirements

- Use OpenZeppelin access control or a similarly well-reviewed, minimal role pattern.
- Restrict verifier, admin, and attestor privileges; test unauthorized calls.
- Make the deployer/admin setup explicit and document role handoff.
- Use Solidity 0.8.x or a currently supported compiler version compatible with the toolchain.
- Avoid upgradeability unless required; do not add it for a hackathon MVP by default.
- Never put the signer private key in the Flutter app or commit a real private key.
- Do not include secrets or personal data in events, revert strings, calldata, or contract storage.
- Think through revocation and repeated proof attempts; a revoked responder should not be considered eligible for new dispatch by the backend.
- Keep gas use simple and predictable; one compact proof event is preferable to writing large records to storage.

## 6. Backend integration semantics

The backend owns the emergency workflow. On milestones such as `RESPONDER_ARRIVED` and `EMERGENCY_RESOLVED`, it persists the off-chain event and queues proof submission asynchronously. Contract/RPC failure must not block the emergency action or any user-visible safety notification.

Backend proof status is off-chain:

`NOT_SUBMITTED` | `PENDING` | `CONFIRMED` | `FAILED`

The backend should expose a transaction hash only when available. `CONFIRMED` must mean the receipt was observed according to the chosen network's confirmation policy. A chain proof is an audit record, not a guarantee the event was true.

For responder verification, decide and document whether application authorization depends on the off-chain verification database, an on-chain status lookup, or both. For the demo, the recommended design is **off-chain verification as the operational source of truth**, with an on-chain attestation as an audit proof; do not make dispatch block on chain RPC availability.

## 7. Required tests

- Only authorized admin can grant/revoke verifier/attestor privileges.
- Only authorized verifier can change responder status.
- Unknown responder defaults to `UNVERIFIED`.
- Only authorized backend attestor can record proof.
- Duplicate proof ID behavior is deterministic and tested.
- Proof fields and event ABI match the backend integration exactly.
- Schema version/event enum validation works as intended.
- Revocation state is correctly reflected.
- Hash test vectors match backend byte-for-byte.
- Deployment and role-setup scripts work on a fresh local chain.

## 8. Deliverables

- Solidity source and meaningful contract tests
- Hardhat config and scripts for compile, test, local deploy, and optional testnet deploy
- ABI artifacts consumed by the backend (do not commit unnecessary build output if repository convention excludes it)
- `.env.example` with placeholder RPC URL, deployer key variable, chain ID, and contract addresses
- README containing deploy commands, role setup, event schema, hash spec/test vectors, local demo flow, and known trust assumptions
- No real personal information and no private keys in source control
