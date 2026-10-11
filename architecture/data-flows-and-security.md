# Sahaay Data Flows, State Machine & Security Architecture

This document provides end-to-end event sequence diagrams, formal state transitions, threat models, and privacy enforcement policies across the Sahaay ecosystem.

---

## 1. End-to-End Event Sequence Flows

### 1.1. Core Incident Lifecycle (SOS $\to$ Match $\to$ Assign $\to$ Arrive $\to$ Resolve $\to$ Blockchain)

```mermaid
sequenceDiagram
    autonumber
    actor Elderly as Elderly User
    actor Responder1 as Nearby Responder 1
    actor Responder2 as Nearby Responder 2
    participant API as Express API (/api/v1)
    participant Engine as Matching Engine
    participant Sockets as Socket.IO Hub
    participant DB as MongoDB
    participant Outbox as Proof Outbox
    participant Ledger as EmergencyLedger.sol

    Elderly->>API: POST /emergencies (category, exact location)
    API->>DB: Emergency.create(status: ACTIVE, exact location)
    API->>DB: EmergencyEvent.create(eventType: CREATED)
    API-->>Elderly: HTTP 201 Created (Full emergency details with exact location)

    API->>Engine: notifyNearbyResponders(emergency)
    Engine->>DB: Query verified & available responders within 500m
    Engine->>Engine: Coarsen exact coordinates to ~100m grid
    Engine->>Sockets: emit EMERGENCY_CREATED to user:responder1 & user:responder2
    Sockets-->>Responder1: Socket event (coarse location, distance ~250m)
    Sockets-->>Responder2: Socket event (coarse location, distance ~380m)

    par Race Condition: Both Responders Accept
        Responder1->>API: POST /emergencies/:id/accept
        API->>DB: Atomic update { status: ACTIVE, assigned: null } -> ASSIGNED
        DB-->>API: Match succeeded!
        API->>Sockets: emit RESPONDER_ACCEPTED
        API-->>Responder1: HTTP 200 OK (Reveals exact coordinates & user details)
    and
        Responder2->>API: POST /emergencies/:id/accept
        API->>DB: Atomic update { status: ACTIVE, assigned: null }
        DB-->>API: Zero matched (already assigned)
        API-->>Responder2: HTTP 409 Conflict (EMERGENCY_ALREADY_ASSIGNED)
    end

    Sockets-->>Elderly: emit RESPONDER_ACCEPTED (Responder name & status)

    Note over Responder1,API: Responder arrives at scene
    Responder1->>API: POST /emergencies/:id/arrive
    API->>DB: Emergency.update(status: RESPONDER_ARRIVED)
    API->>Outbox: Enqueue ARRIVED proof (NOT_SUBMITTED)
    API->>Sockets: emit RESPONDER_ARRIVED
    API-->>Responder1: HTTP 200 OK

    Note over Responder1,API: Responder assists and closes incident
    Responder1->>API: POST /emergencies/:id/resolve (outcome: ASSISTED)
    API->>DB: Emergency.update(status: RESOLVED, outcome: ASSISTED)
    API->>DB: Increment Responder completedCount & reputationScore
    API->>Outbox: Enqueue RESOLVED proof (NOT_SUBMITTED)
    API->>Sockets: emit EMERGENCY_RESOLVED
    API-->>Responder1: HTTP 200 OK

    Note over Outbox,Ledger: Background Trust Worker
    Outbox->>Ledger: recordProof(proofId, payloadHash)
    Ledger-->>Outbox: ProofRecorded Event Confirmed
```

---

### 1.2. Responder Credentialing Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Volunteer as Volunteer Applicant
    actor Verifier as NGO Coordinator / Admin
    participant API as Express API (/api/v1)
    participant DB as MongoDB
    participant Registry as ResponderRegistry.sol

    Volunteer->>API: POST /auth/register (requestedRole: VOLUNTEER)
    API->>DB: User.create(role: VOLUNTEER)
    API->>DB: ResponderProfile.create(verificationStatus: PENDING)
    API-->>Volunteer: HTTP 201 Created (Profile Pending Review)

    Verifier->>API: GET /admin/responders/pending
    API->>DB: Query profiles where verificationStatus == PENDING
    API-->>Verifier: Return applicant list & credentials

    Verifier->>API: POST /admin/responders/:id/verify
    API->>DB: Update ResponderProfile verificationStatus -> VERIFIED
    API->>DB: VerificationAudit.create(action: VERIFY, verifierId)
    API-->>Verifier: HTTP 200 OK (Profile Verified)

    Verifier->>Registry: setResponderStatus(responderRef, VERIFIED)
    Registry-->>Verifier: Emit ResponderStatusChanged(responderRef, 1)
```

---

## 2. Emergency State Machine Specification

The state machine implements strict validation guards to prevent illegal transitions:

| Current Status | Target Status | Triggering Action | Allowed Actor | Guard Conditions |
|---|---|---|---|---|
| *Initial* | `ACTIVE` | `POST /emergencies` | `ELDERLY_USER` | Authenticated owner; valid category and location. |
| `ACTIVE` | `ASSIGNED` | `POST /emergencies/:id/accept` | `RESPONDER` | Atomic match: `status == ACTIVE` and `assignedResponderId == null`. Responder must be `VERIFIED` and `available`. |
| `ACTIVE` | `CANCELLED` | `POST /emergencies/:id/cancel` | `ELDERLY_USER` | Incident owner only; cannot cancel once assigned. |
| `ASSIGNED` | `RESPONDER_ARRIVED` | `POST /emergencies/:id/arrive` | `RESPONDER` | Assigned responder only; cannot arrive if unassigned. |
| `ACTIVE` / `ASSIGNED` / `RESPONDER_ARRIVED` | `ESCALATED` | `POST /emergencies/:id/escalate` | `ELDERLY_USER` or `RESPONDER` | Must provide escalation reason; preserves existing assigned responder and event history. |
| `ASSIGNED` / `RESPONDER_ARRIVED` / `ESCALATED` | `RESOLVED` | `POST /emergencies/:id/resolve` | `RESPONDER` | Assigned responder only; valid resolution outcome required (`ASSISTED`, `REFERRED_TO_EMERGENCY_SERVICES`, etc.). |

---

## 3. Threat Modeling & Security Mitigations

| Threat Vector | Attack Mechanism | Sahaay Mitigation Strategy |
|---|---|---|
| **Stalking / Location Privacy Harvest** | Rogue responder creates account to spy on elderly residents' locations. | **1. Location Coarsening**: Pre-acceptance coordinates are rounded to ~100m grid cells.<br>**2. Strict RBAC**: Unverified or unavailable responders cannot query `/emergencies/nearby`.<br>**3. Post-Acceptance Auditing**: Exact coordinates are revealed to exactly ONE responder per incident, backed by immutable audit logs. |
| **Race Conditions (Double Assignment)** | Two responders simultaneously click "Accept" on the same SOS. | **Atomic Conditional Update**: MongoDB `findOneAndUpdate({ _id, status: 'ACTIVE', assignedResponderId: null })`. Only the first database write succeeds; the second receives HTTP `409 Conflict`. |
| **Privilege Escalation** | Attacker registers with `requestedRole: 'ADMIN'` to approve fake responders. | **Role Whitelisting**: Registration middleware rejects privileged roles (`ADMIN`, `VERIFIER`). Administrative credentials are provisioned exclusively via database migrations or seed scripts. |
| **Tampered Incident History** | Rogue database administrator alters resolution outcomes or timestamps. | **Cryptographic On-Chain Attestation**: Any modification of the off-chain record changes the SHA-256 digest, which will fail comparison against the immutable on-chain `payloadHash`. |
| **Hot Wallet Compromise** | Backend server compromised; attacker steals private key. | **Compartmentalized Access Control**: The backend wallet possesses only `ATTESTOR_ROLE`. It cannot transfer contract ownership, mint tokens, or modify responder verification states. Admin multisig can revoke the key instantaneously. |
| **Denial of Service / SOS Spam** | Script floods API with false emergency requests. | **1. IP Rate Limiting**: Express middleware limits high-frequency requests.<br>**2. JWT Session Verification**: Anonymous requests are dropped.<br>**3. Geographic Density Guards**: Duplicate active emergencies for the same user are restricted. |
