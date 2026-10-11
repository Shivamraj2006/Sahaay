# Sahaay — Backend Handoff

**Audience:** Node.js/backend coding agent. Read `00-shared-contract.md` first; it is authoritative.

## 1. Scope and stack

Implement the API and authoritative emergency workflow using Node.js, TypeScript, Express, MongoDB/Mongoose, Socket.IO, Zod validation, JWT authentication, and a password-hashing library. Use Redis only if needed for a concrete purpose; do not add queues or infrastructure without an MVP need. FCM push support is optional when credentials are unavailable, but its integration boundary and local fallback must be clear. Use Ethers.js for asynchronous trust-layer submissions.

## 2. Core modules

Suggested feature modules:

- `auth`: register/login/token handling and role authorization
- `users`: current user/profile
- `responders`: responder profile, availability, location freshness, history, reputation
- `emergencies`: create, retrieve, cancel, accept, decline, arrive, resolve, escalate
- `matching`: radius expansion and responder eligibility
- `realtime`: Socket.IO authentication, room permissions, canonical events
- `notifications`: socket notification plus optional FCM
- `verification`: review/verify/revoke with audit trail
- `trust`: canonical proof serialization/hash, outbox/retry, EVM submission status
- `admin`: restricted verification routes

## 3. Data model guidance

Use explicit schemas and indexes. The exact schema can evolve if API behavior stays stable.

### User
- opaque ID
- `displayName`
- normalized phone/login identifier
- password hash (never plaintext)
- server-assigned `role`
- optional user preferences
- `createdAt`, `updatedAt`

### ResponderProfile
- `userId` (unique reference)
- `verificationStatus`
- permitted capability tags
- `available`
- latest permitted location plus `locationUpdatedAt`
- verification metadata and audit references
- completed count/reputation projection (derived from accepted completed events, not user-editable)

Use geospatial indexes only for operational location data. Restrict who can query it. Avoid retaining route/location history unnecessarily.

### Emergency
- opaque ID and owner ID
- category/status
- exact location held off-chain
- assigned responder ID, nullable until assigned
- creation/update timestamps and version number
- cancellation metadata
- escalation details and preserved prior-state context
- resolution outcome and limited operational note
- proof-submission metadata

### EmergencyEvent (append-only application history)
- opaque event ID, emergency ID, actor ID/role
- event type, previous status, next status
- timestamp, version, request/correlation ID
- privacy-safe metadata only

### VerificationAudit
- responder ID, actor ID, action, status before/after, timestamp, reason/reference as allowed
- no unnecessary identity documents or high-risk personal information

### ProofOutbox
- stable event/proof ID, emergency ID, event type, canonical schema version and digest
- current proof status, retry count, timestamps, transaction hash, failure code
- no personal fields or exact coordinates

## 4. API requirements

Implement the routes and payloads in the shared contract and publish OpenAPI. Validate every request and relevant query with Zod (or an equivalent validation layer). Standardize response envelopes/errors, status codes, authentication, and authorization. Add pagination for history/admin lists if required by the chosen schema.

Expected behavior:

- `POST /emergencies`: validate category/location, create `ACTIVE` emergency and event record, dispatch notifications, return owner-authorized representation.
- `GET /emergencies/nearby`: responder-only, eligible active emergencies in the current matching radius; redact exact coordinates and owner contact information.
- `POST /emergencies/:id/accept`: atomic conditional update, e.g. update only where `_id` matches, status is `ACTIVE`, and assignment is absent. A zero-match means conflict/no longer available.
- `POST /emergencies/:id/cancel`: owner-only and state-guarded; atomically stop unclaimed dispatch when possible. If assignment already succeeded, return a conflict/state-aware response rather than pretending it was cancelled.
- `POST /emergencies/:id/arrive`: assigned responder only; record append-only event and move to `RESPONDER_ARRIVED`.
- `POST /emergencies/:id/resolve`: assigned responder only and valid from documented statuses; append resolution event and enqueue proof after the DB transaction succeeds.
- `POST /emergencies/:id/escalate`: authorized emergency owner/assigned responder according to the final permission matrix; retain assignment and history; notify the appropriate parties.
- verify/revoke routes: verifier/admin only; record audit events and ensure revoked responders are not eligible for new assignments.

Use MongoDB transactions when supported by deployment, or equivalent carefully designed conditional writes and an outbox pattern. Never hold a database transaction open while waiting for blockchain RPC, push notification, or socket delivery.

## 5. Matching and escalation

Configurable defaults:

- initial radius: `500` meters
- next radius: `1000` meters
- maximum radius: `3000` meters
- location freshness threshold: define and test a reasonable limit (suggestion: 2–5 minutes for active responders)

Candidate eligibility: verified, available, fresh location, within radius, and compatible capability. De-duplicate candidates and notifications. Expand gradually with bounded delay, stop if assigned/cancelled/resolved, and avoid unbounded background loops. Provide a manual/test mode for the demo that allows deterministic matching without spoofing production behavior.

The response selection algorithm must be documented. A simple MVP can sort by distance and then a stable tie-break. Reputation is not proof of competence and should not override verification/eligibility.

## 6. Concurrency, idempotency, and versioning

- Assignment must be atomic. A second acceptance must receive `409 Conflict` or another documented state-aware response.
- State transitions use compare-and-set/status guards, increment a version, and append an event.
- Avoid duplicate notification loops and duplicate trust proofs. Use a unique proof/event identifier and a unique index where practical.
- Client should refetch if a Socket.IO event version is behind or skips a version.
- If idempotency keys are supported, define the exact header, retention, and response replay behavior in OpenAPI. Otherwise ensure clients do not blindly retry non-idempotent requests.
- Ensure cancel/accept/escalate races have deterministic tests.

## 7. Socket.IO contract

Emit the exact event names and envelope in the shared contract. Authenticate on connection, authorize all rooms server-side, and validate ownership/assignment before sending data. Emit status/version metadata, not a duplicate unrestricted copy of the whole emergency document. Payloads must be filtered per recipient so only the assigned responder gets exact location after assignment. Socket delivery is best-effort; persist state first and rely on REST refetch for recovery.

## 8. Security and privacy checklist

- Hash passwords using a current, appropriate password-hashing scheme.
- Use expiring JWTs and never place signing secrets or database credentials in source control.
- Never trust a client-supplied role, responder status, reputation, emergency status, or assignment.
- Protect all route and socket actions with authorization and object-level access checks.
- Do not expose exact locations via nearby APIs, global socket rooms, public logs, analytics, or chain transactions.
- Rate-limit auth and SOS-related endpoints and add basic abuse controls.
- Validate coordinate ranges and timestamps; guard against stale/fabricated responder locations to the extent feasible for MVP.
- Keep audit logs privacy-safe; redact secrets and sensitive request bodies.
- Do not collect Aadhaar data for the MVP.

## 9. Blockchain integration

Implement a background-compatible proof outbox, even if processed by a simple in-process worker for the hackathon. The emergency write must commit before proof submission. Suggested process:

1. Persist state/event and proof-outbox item atomically where practical.
2. Worker finds `NOT_SUBMITTED` items, constructs canonical privacy-safe record, submits transaction using backend signer.
3. Mark `PENDING` with transaction hash; monitor receipt.
4. Mark `CONFIRMED` only when receipt is confirmed according to the configured network policy.
5. On failure, record a safe failure code and retry with bounded backoff; eventually mark `FAILED` and surface it as an audit-layer issue, not an emergency failure.

Use only authorized contract methods. Keep private keys in environment/secrets management; never in the mobile app. Contract address, chain ID, RPC URL, and signer key are configuration. No personal data in calldata or events.

### Hash implementation

Coordinate directly with the blockchain agent before implementation. Freeze canonical record schema, key order/encoding, version, timestamp normalization, and digest algorithm. Create shared test vectors in source control and test in both layers. Do not hash a raw database document whose field order or private fields may change. Do not use ambiguous string concatenation.

## 10. Tests required

- Auth/role/object-ownership checks for each endpoint
- Invalid category/status/coordinate payloads rejected
- Assignment race test with two responders: exactly one accepted
- Cancel-versus-accept race outcomes are safe and documented
- Revoked/unverified/unavailable/stale responders cannot be assigned
- Nearby endpoint redacts exact location and private user details
- Only assigned responder receives exact location after assignment
- Socket room authorization and payload redaction tests
- Event history, version increments, and legal/illegal transitions
- Outbox retry/idempotency and proof hash test vectors
- Blockchain RPC failure does not change SOS/resolve success semantics

## 11. Local developer experience

Provide `.env.example`, seed/demo users with clear roles and verification states, setup/run/test commands, and a complete scripted demo path. Document which features need MongoDB, Redis (if any), FCM, and an EVM RPC. If FCM or blockchain RPC is not configured, fail gracefully with explicit status rather than false success. Do not commit `.env`, test private keys beyond clearly designated local-only development keys, or real personal data.
