# Sahaay Shared Agent Handoff Pack

These Markdown files are the shared handoff pack for the Sahaay hackathon MVP. Share the full folder (or ZIP) with every coding agent.

## Files

- `00-shared-contract.md` — canonical product behavior, enums, API paths, state transitions, privacy, real-time events, and blockchain boundary. **All agents must read this first.**
- `01-flutter-client-contract.md` — frontend screens, app behavior, API use, state management, location privacy, and frontend tests.
- `02-backend-contract.md` — API/backend responsibilities, data models, matching, concurrency, sockets, security, proof outbox, and tests.
- `03-blockchain-contract.md` — Solidity contract responsibilities, access control, canonical hashes, backend integration, and tests.
- `04-integration-checklist.md` — cross-layer acceptance tests and the end-to-end demo path.

## Suggested agent assignment

1. **Flutter agent:** `00-shared-contract.md` + `01-flutter-client-contract.md`
2. **Backend agent:** `00-shared-contract.md` + `02-backend-contract.md`
3. **Blockchain agent:** `00-shared-contract.md` + `03-blockchain-contract.md`
4. **Integrator/QA:** all files, especially `04-integration-checklist.md`

## Important coordination rule

The shared contract is the source of truth, but the backend's actual OpenAPI specification becomes the machine-readable source for the real API once published. The backend and blockchain agents must also agree on canonical hash encoding and shared test vectors before independently finalizing proof code. Any proposed change to enums, endpoints, state transitions, event payloads, or hash fields must be communicated to all agents and reflected in the shared documentation.
