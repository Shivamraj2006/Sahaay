// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title EmergencyLedger
 * @dev Tamper-evident on-chain audit ledger for Sahaay emergency milestones.
 *
 * Privacy & Security:
 * - Only records pseudonymous references and canonical SHA-256 payload digests.
 * - Zero PII: no names, phones, medical records, or coordinates are stored or emitted.
 * - Authorized attestors (backend signer) only.
 * - Proof IDs are unique to guarantee idempotency and replay protection.
 */
contract EmergencyLedger is AccessControl {
    bytes32 public constant ATTESTOR_ROLE = keccak256("ATTESTOR_ROLE");

    enum ProofEventType {
        RESPONDER_ARRIVED, // 0 - milestone: assigned responder reached the user
        EMERGENCY_RESOLVED  // 1 - milestone: emergency resolved with outcome
    }

    struct ProofRecord {
        bytes32 proofId;
        bytes32 emergencyRef;
        bytes32 responderRef;
        ProofEventType eventType;
        uint16 schemaVersion;
        bytes32 payloadHash;
        address attestor;
        uint256 blockTimestamp;
        bool exists;
    }

    // Mapping from unique proof ID to ProofRecord
    mapping(bytes32 => ProofRecord) private _proofs;

    // Counter of total proofs recorded
    uint256 public totalProofs;

    /**
     * @dev Emitted when a milestone proof is recorded on-chain.
     */
    event ProofRecorded(
        bytes32 indexed proofId,
        bytes32 indexed emergencyRef,
        bytes32 indexed responderRef,
        ProofEventType eventType,
        uint16 schemaVersion,
        bytes32 payloadHash,
        address attestor,
        uint256 blockTimestamp
    );

    /**
     * @dev Constructor grants DEFAULT_ADMIN_ROLE to deployer.
     * @param admin Initial administrator address
     */
    constructor(address admin) {
        require(admin != address(0), "INVALID_ADMIN_ADDRESS");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Grant or revoke the ATTESTOR_ROLE for an account.
     * Can only be called by accounts with DEFAULT_ADMIN_ROLE.
     */
    function setAttestor(address account, bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "INVALID_ACCOUNT_ADDRESS");
        if (enabled) {
            _grantRole(ATTESTOR_ROLE, account);
        } else {
            _revokeRole(ATTESTOR_ROLE, account);
        }
    }

    /**
     * @dev Record a milestone proof in the tamper-evident ledger.
     * Only accounts with ATTESTOR_ROLE can call this method.
     *
     * @param proofId Unique, non-reusable identifier for this proof event
     * @param emergencyRef Pseudonymous emergency reference
     * @param responderRef Pseudonymous responder reference
     * @param eventType Milestone event type (RESPONDER_ARRIVED or EMERGENCY_RESOLVED)
     * @param schemaVersion Version of the canonical proof schema
     * @param payloadHash SHA-256 digest of canonical proof JSON formatted as bytes32
     */
    function recordProof(
        bytes32 proofId,
        bytes32 emergencyRef,
        bytes32 responderRef,
        ProofEventType eventType,
        uint16 schemaVersion,
        bytes32 payloadHash
    ) external onlyRole(ATTESTOR_ROLE) {
        require(proofId != bytes32(0), "INVALID_PROOF_ID");
        require(emergencyRef != bytes32(0), "INVALID_EMERGENCY_REF");
        require(responderRef != bytes32(0), "INVALID_RESPONDER_REF");
        require(schemaVersion > 0, "INVALID_SCHEMA_VERSION");
        require(payloadHash != bytes32(0), "INVALID_PAYLOAD_HASH");
        require(!_proofs[proofId].exists, "PROOF_ALREADY_RECORDED");

        _proofs[proofId] = ProofRecord({
            proofId: proofId,
            emergencyRef: emergencyRef,
            responderRef: responderRef,
            eventType: eventType,
            schemaVersion: schemaVersion,
            payloadHash: payloadHash,
            attestor: msg.sender,
            blockTimestamp: block.timestamp,
            exists: true
        });

        totalProofs++;

        emit ProofRecorded(
            proofId,
            emergencyRef,
            responderRef,
            eventType,
            schemaVersion,
            payloadHash,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Check whether a proof has already been recorded.
     */
    function hasProof(bytes32 proofId) external view returns (bool) {
        return _proofs[proofId].exists;
    }

    /**
     * @dev Retrieve recorded proof details.
     */
    function getProof(bytes32 proofId) external view returns (ProofRecord memory) {
        require(_proofs[proofId].exists, "PROOF_NOT_FOUND");
        return _proofs[proofId];
    }
}
