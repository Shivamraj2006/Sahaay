// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ResponderRegistry
 * @dev Manages on-chain verification attestations for Sahaay emergency responders.
 *
 * Privacy & Security:
 * - Only pseudonymous, opaque bytes32 references are recorded.
 * - Zero personal identifiability (no names, phones, government IDs, coordinates).
 * - Access-controlled: Only authorized VERIFIER_ROLE accounts can attest verification or revocation.
 * - Unknown responders default safely to UNVERIFIED (0).
 */
contract ResponderRegistry is AccessControl {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    enum VerificationStatus {
        UNVERIFIED, // 0 - default state
        VERIFIED,   // 1 - authorized community responder
        REVOKED     // 2 - revoked responder
    }

    // Mapping from pseudonymous responder reference to verification status
    mapping(bytes32 => VerificationStatus) private _responderStatuses;

    /**
     * @dev Emitted when a responder's verification status is changed.
     * @param responderRef Pseudonymous bytes32 reference of the responder
     * @param status The new VerificationStatus
     * @param verifier The address of the verifier who performed the action
     * @param timestamp Block timestamp of the attestation
     */
    event ResponderStatusChanged(
        bytes32 indexed responderRef,
        VerificationStatus status,
        address indexed verifier,
        uint256 timestamp
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
     * @dev Grant or revoke the VERIFIER_ROLE for an account.
     * Can only be called by accounts with DEFAULT_ADMIN_ROLE.
     */
    function setVerifier(address account, bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "INVALID_ACCOUNT_ADDRESS");
        if (enabled) {
            _grantRole(VERIFIER_ROLE, account);
        } else {
            _revokeRole(VERIFIER_ROLE, account);
        }
    }

    /**
     * @dev Record or update the verification status of a responder.
     * Can only be called by accounts with VERIFIER_ROLE.
     * @param responderRef Pseudonymous responder reference
     * @param status New VerificationStatus (VERIFIED or REVOKED)
     */
    function setResponderStatus(
        bytes32 responderRef,
        VerificationStatus status
    ) external onlyRole(VERIFIER_ROLE) {
        require(responderRef != bytes32(0), "INVALID_RESPONDER_REF");
        require(status != VerificationStatus.UNVERIFIED, "CANNOT_SET_TO_UNVERIFIED");

        _responderStatuses[responderRef] = status;

        emit ResponderStatusChanged(
            responderRef,
            status,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Retrieve the verification status of a responder.
     * Unregistered responders default to UNVERIFIED (0).
     */
    function getResponderStatus(bytes32 responderRef) external view returns (VerificationStatus) {
        return _responderStatuses[responderRef];
    }

    /**
     * @dev Check if a responder is actively verified.
     */
    function isVerified(bytes32 responderRef) external view returns (bool) {
        return _responderStatuses[responderRef] == VerificationStatus.VERIFIED;
    }
}
