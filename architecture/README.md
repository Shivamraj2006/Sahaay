# Sahaay Architecture Documentation

Welcome to the architectural specifications and design documentation for **Sahaay** — a decentralized, community-driven emergency-response network designed for elderly individuals living alone in urban India.

---

## 🏛️ System Overview

Sahaay combines high-throughput, low-latency off-chain emergency dispatch with an immutable, privacy-preserving EVM trust layer. The architecture explicitly decouples operational safety from blockchain finality:

1. **Backend Layer (Operational Core)**: Owns authentication, geospatial matching, atomic state transitions, real-time WebSocket communication, and location privacy enforcement.
2. **Blockchain Layer (Audit & Trust Core)**: Provides a tamper-evident audit ledger (`EmergencyLedger.sol`) for rescue milestones and an on-chain credential registry (`ResponderRegistry.sol`) for verified responders, without storing any Personal Identifiable Information (PII).
3. **Integration Bridge (Asynchronous Outbox)**: Guarantees zero blocking of emergency dispatch while ensuring reliable, eventually consistent on-chain attestation via canonical SHA-256 payload digests.

```mermaid
flowchart TB
    subgraph ClientLayer["Client Layer"]
        Elderly[Elderly Mobile App]
        Responder[Responder Mobile App]
        AdminUI[Admin / Verifier Web]
    end

    subgraph BackendLayer["Backend Layer (Node.js / Express / MongoDB)"]
        API[Express REST API /api/v1]
        SocketIO[Socket.IO Real-Time Gateway]
        StateEngine[Emergency State Machine]
        MatchingEngine[Geospatial Matching Engine]
        PrivacyFilter[Location Coarsening & Privacy Layer]
        DB[(MongoDB Database)]
        Outbox[(Proof Outbox)]
        Worker[Trust Worker Process]
    end

    subgraph BlockchainLayer["Blockchain Layer (EVM / Solidity)"]
        EmergencyLedgerContract[EmergencyLedger.sol]
        ResponderRegistryContract[ResponderRegistry.sol]
    end

    Elderly -->|1. SOS Request| API
    API --> StateEngine
    StateEngine --> DB
    StateEngine --> MatchingEngine
    MatchingEngine --> PrivacyFilter
    PrivacyFilter -->|2. Coarse Alert| SocketIO
    SocketIO --> Responder

    Responder -->|3. Accept / Arrive / Resolve| API
    StateEngine -->|4. Exact Location Post-Assignment| Responder
    StateEngine -->|5. Enqueue Milestone| Outbox
    Worker -->|6. Poll & Batch Process| Outbox
    Worker -->|7. Submit Canonical Digest (bytes32)| EmergencyLedgerContract

    AdminUI -->|Verify Responder| API
    API --> DB
    AdminUI -.->|Direct On-Chain Attestation| ResponderRegistryContract
```

---

## 📚 Document Index

| Document | Focus & Scope |
|---|---|
| [**Backend Architecture**](file:///home/shivam/Projects/Sahay/architecture/backend-architecture.md) | In-depth breakdown of Node.js, Express, MongoDB schemas, state machines, atomic concurrency guards, matching engine with radius expansion, and WebSocket architecture. |
| [**Blockchain Architecture**](file:///home/shivam/Projects/Sahay/architecture/blockchain-architecture.md) | Solidity smart contracts (`EmergencyLedger`, `ResponderRegistry`), OpenZeppelin RBAC, pseudonymous `bytes32` identifier schemes, zero-PII storage invariants, and deployment workflows. |
| [**Cross-Layer Integration**](file:///home/shivam/Projects/Sahay/architecture/cross-layer-integration.md) | Outbox pattern, canonical JSON serialization & SHA-256 digestion, background worker retry mechanics, failure isolation, and cross-layer test vectors. |
| [**Data Flows, State Machine & Security**](file:///home/shivam/Projects/Sahay/architecture/data-flows-and-security.md) | End-to-end event sequence diagrams, formal state transition tables, terminal states, ~100m location coarsening mechanism, and the zero-trust privacy envelope. |

---

## 🎯 Core Architectural Invariants

The architecture enforces strict invariants across all layers:

1. **Non-Blocking Dispatch Invariant**:
   Under no circumstances may a blockchain transaction, RPC latency, gas price spike, or network outage delay an SOS creation, responder alert, assignment, or resolution.
2. **Zero-PII On-Chain Invariant**:
   Names, phone numbers, exact latitude/longitude coordinates, medical notes, Aadhaar numbers, or user messages are **strictly prohibited** from calldata, contract storage, or contract event logs. Only non-reversible `bytes32` hashes and pseudonymous references are published.
3. **Location Privacy Invariant**:
   Exact GPS coordinates are visible only to the emergency owner and the assigned responder **after** assignment is atomically committed. Pre-acceptance responders receive only ~100m grid-coarsened coordinates and approximate distance.
4. **Atomic Assignment Invariant**:
   Multiple responders attempting to accept the same emergency must be resolved atomically via database conditional writes. At most one responder can be assigned; all subsequent attempts receive HTTP `409 Conflict`.
5. **Deterministic Auditability Invariant**:
   Every off-chain milestone submitted to the blockchain is calculated via a frozen canonical JSON serialization with sorted keys and normalized ISO 8601 UTC timestamps, guaranteeing byte-for-byte reproducibility between backend services, contracts, and third-party auditors.
