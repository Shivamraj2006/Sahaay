# Sahaay

> **Community Emergency-Response Network for Elderly People Living Alone in Urban India**

Sahaay combines high-throughput, low-latency off-chain emergency dispatch with an immutable, privacy-preserving EVM trust layer.

---

## 🏛️ Architecture Documentation

Comprehensive technical documentation explaining the working of each layer is located in the [**`architecture/`**](file:///home/shivam/Projects/Sahay/architecture/README.md) directory:

- [**System Overview & Architecture Index**](file:///home/shivam/Projects/Sahay/architecture/README.md): System context, architectural invariants, component relationships, and quick navigation.
- [**Backend Architecture**](file:///home/shivam/Projects/Sahay/architecture/backend-architecture.md): Node.js, Express, MongoDB schemas, state machines, atomic concurrency guards, matching engine with radius expansion, and WebSocket architecture.
- [**Blockchain Architecture**](file:///home/shivam/Projects/Sahay/architecture/blockchain-architecture.md): Solidity smart contracts (`EmergencyLedger`, `ResponderRegistry`), OpenZeppelin RBAC, pseudonymous `bytes32` identifier schemes, and zero-PII storage invariants.
- [**Cross-Layer Integration & Trust Protocol**](file:///home/shivam/Projects/Sahay/architecture/cross-layer-integration.md): Asynchronous outbox pattern, canonical JSON serialization & SHA-256 digestion, background worker retry mechanics, failure isolation, and cross-layer test vectors.
- [**Data Flows, State Machine & Security**](file:///home/shivam/Projects/Sahay/architecture/data-flows-and-security.md): End-to-end event sequence diagrams, formal state transition tables, terminal states, ~100m location coarsening mechanism, and threat modeling.

---

## 📁 Repository Structure

```
Sahaay/
├── architecture/      # Detailed architectural specifications & design documents
│   ├── README.md
│   ├── backend-architecture.md
│   ├── blockchain-architecture.md
│   ├── cross-layer-integration.md
│   └── data-flows-and-security.md
├── backend/           # Node.js + TypeScript + Express + MongoDB + Socket.IO API
│   ├── src/           # Application source code
│   ├── tests/         # Automated Vitest test suites (38 passing tests)
│   └── openapi.json   # OpenAPI 3.0 specification
├── blockchain/        # Solidity + Hardhat + Ethers.js v6 Trust Layer
│   ├── contracts/     # EmergencyLedger.sol & ResponderRegistry.sol
│   ├── scripts/       # Deployment and cross-layer verification scripts
│   └── test/          # Hardhat automated tests (22 passing tests)
├── frontend/          # Flutter Material 3 Mobile Client (Stitch Design Clone)
│   ├── lib/           # App screens, state providers, and widgets
│   ├── assets/        # Visual assets and seed avatar photos
│   └── test/          # Automated model and flow tests
└── Plan/              # Shared product contracts & integration checklists
```
