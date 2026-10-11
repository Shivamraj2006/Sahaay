# Sahaay — Shared Product and Integration Contract

**Purpose:** Canonical interface and behavior agreement for the Flutter, backend, and blockchain workstreams. All agents must read this file before coding. If an implementation detail conflicts with this document, this document is the default source of truth; raise proposed changes explicitly rather than silently diverging.

**Product:** Sahaay is a community emergency-response network for elderly people living alone in urban India. It helps connect a person in distress with nearby, verified responders. It complements public emergency services; it does not replace 112, 108, police, hospitals, or professional emergency care.

## 1. MVP end-to-end journey

1. An elderly user signs in and presses **SOS**.
2. The app presents a short cancellation countdown. The backend must still safely handle cancellation/dispatch races; the countdown is not a security boundary.
3. An emergency is created, persisted, and marked `ACTIVE`. Nearby verified and available responders are notified.
4. Responders see a coarse location and approximate distance before they accept. They must not receive exact coordinates before assignment.
5. The backend atomically assigns the emergency to one responder and changes the status to `ASSIGNED`. Only then may the assigned responder receive exact location details.
6. The responder marks arrival; status becomes `RESPONDER_ARRIVED`.
7. The responder records a resolution or requests escalation. The backend remains authoritative for all transitions.
8. Backend writes event history and asynchronously submits selected tamper-evident proofs to the blockchain. Blockchain delay or failure must never block SOS, dispatch, emergency state changes, or notifications.

## 2. Roles and permissions

Role enum:

- `ELDERLY_USER`
- `VOLUNTEER`
- `MEDICAL_PROFESSIONAL`
- `ORGANIZATION_COORDINATOR`
- `VERIFIER`
- `ADMIN`

MVP dispatch may assign only responders with `verificationStatus = VERIFIED`, availability enabled, a recent usable location, and compatible capabilities. Client-provided roles and verification claims are never trusted; the backend checks authorization on every protected request.

Suggested permissions:

| Action | Elderly user | Assigned responder | Verifier/Admin |
|---|---|---|---|
| Create SOS | Yes | No | No (unless acting as a user in testing) |
| View own emergency | Yes | Yes, if assigned | Authorized support access only |
| View exact location | Emergency owner | Assigned responder after assignment | Avoid by default; only if operationally necessary and audited |
| Accept/decline | No | Eligible verified responder | No |
| Mark arrived/resolve | No | Assigned responder | No |
| Verify/revoke responder | No | No | Yes, with audit log |

## 3. Shared enums

### Emergency category

`MEDICAL` | `FALL_INJURY` | `HOSPITAL_ASSISTANCE`

### Emergency status

`ACTIVE` | `ASSIGNED` | `RESPONDER_ARRIVED` | `ESCALATED` | `RESOLVED` | `CANCELLED`

`ESCALATED` records that additional help or a public emergency service is needed. It must not erase the assigned responder or prior event history. The backend may preserve the prior status in an event record and route additional notifications. Terminal statuses are `RESOLVED` and `CANCELLED`, unless product owners explicitly approve a different state machine.

### Verification status

`UNVERIFIED` | `PENDING` | `VERIFIED` | `REVOKED`

### Proof submission status (off-chain)

`NOT_SUBMITTED` | `PENDING` | `CONFIRMED` | `FAILED`

## 4. State transition rules

The backend owns the state machine; clients request transitions and render the authoritative result.

| Current state | Command | Next state | Required guard |
|---|---|---|---|
| — | Create SOS | `ACTIVE` | Authenticated owner; valid category and location |
| `ACTIVE` | Accept | `ASSIGNED` | Atomic conditional update; responder verified, available, eligible; no existing assignment |
| `ACTIVE` | Cancel | `CANCELLED` | Authenticated emergency owner; still active |
| `ASSIGNED` | Mark arrived | `RESPONDER_ARRIVED` | Authenticated assigned responder |
| `ACTIVE`, `ASSIGNED`, `RESPONDER_ARRIVED` | Escalate | `ESCALATED` | Authorized actor; preserve prior status, assignment, and audit trail |
| `ASSIGNED`, `RESPONDER_ARRIVED`, `ESCALATED` | Resolve | `RESOLVED` | Authenticated assigned responder; resolution outcome recorded |
| `ESCALATED` | Resume/continue | Must be explicit | Do not invent an implicit transition; document it in tests if implemented |

Reject invalid or stale transitions with HTTP `409 Conflict`. Make accept/assign atomic so two responders cannot win the same emergency. Cancellation, acceptance, and escalation races must be handled on the server.

## 5. Canonical API conventions

- Base path: `/api/v1`
- JSON request and response bodies.
- IDs are opaque strings; clients must not depend on MongoDB internals.
- Timestamps are ISO 8601 UTC strings, e.g. `2026-10-11T08:30:00.000Z`.
- Coordinates use WGS84: latitude and longitude in decimal degrees. For GeoJSON storage, the order is `[longitude, latitude]`; in API objects use `{ "latitude": ..., "longitude": ... }` to reduce client confusion.
- Use authenticated bearer access tokens for protected APIs.
- Standard error shape:

```json
{
  "error": {
    "code": "EMERGENCY_ALREADY_ASSIGNED",
    "message": "This emergency has already been assigned.",
    "requestId": "opaque-request-id",
    "details": {}
  }
}
```

`details` may be omitted. Never include stack traces, secrets, private location, or medical data in errors or logs.

## 6. API surface

All endpoints below are proposed MVP contracts. The backend owner must publish the matching OpenAPI definition before integration; every agent should use these paths and field names.

### Authentication and user

- `POST /auth/register`
- `POST /auth/login`
- `GET /users/me`
- `PATCH /users/me`

Suggested register body:

```json
{
  "displayName": "Example User",
  "phone": "+91XXXXXXXXXX",
  "password": "user-supplied-secret",
  "requestedRole": "ELDERLY_USER"
}
```

For a real deployment, use an appropriate OTP/phone verification process and abuse controls. A demo may use seeded accounts. Never store plaintext passwords. Users must not be able to self-assign privileged roles such as `VERIFIER` or `ADMIN`.

### Responder

- `GET /responders/me`
- `PATCH /responders/me/availability`
- `GET /responders/me/history`
- `GET /responders/me/reputation`

Availability body:

```json
{ "available": true }
```

Responders may update their own availability and permitted profile fields, but must not update their own verification status, role, reputation, completed count, or verification evidence.

### Emergencies

- `GET /emergencies/nearby` — responder-only; returns eligible nearby active emergencies with coarse location and approximate distance.
- `POST /emergencies` — create an SOS.
- `GET /emergencies/:id` — owner, assigned responder, or other explicitly authorized actor only.
- `POST /emergencies/:id/cancel`
- `POST /emergencies/:id/accept`
- `POST /emergencies/:id/decline`
- `POST /emergencies/:id/arrive`
- `POST /emergencies/:id/resolve`
- `POST /emergencies/:id/escalate`

Example create body:

```json
{
  "category": "FALL_INJURY",
  "location": { "latitude": 21.1458, "longitude": 79.0882 },
  "notes": "Optional short note; avoid unnecessary medical detail."
}
```

Do not send exact coordinates to ineligible responders or broadcast them in a general Socket.IO room. The create response is visible to the owner and may include the owner's exact location; responder-facing payloads follow the location privacy policy below.

Example resolve body:

```json
{
  "outcome": "ASSISTED",
  "note": "Optional short, non-sensitive operational note."
}
```

Keep outcomes to a documented enum in implementation (for example `ASSISTED`, `REFERRED_TO_EMERGENCY_SERVICES`, `NO_CONTACT`, `OTHER`). Do not put clinical records or sensitive free text on-chain.

### Admin and verification

- `GET /admin/responders/pending`
- `POST /admin/responders/:id/verify`
- `POST /admin/responders/:id/revoke`

These require `VERIFIER` or `ADMIN` according to the backend's permission matrix. Verification and revocation must be auditable. For the hackathon MVP, verification can be completed by an authorized seeded/admin account. Do not integrate Aadhaar or collect Aadhaar numbers/documents as a shortcut.

## 7. Suggested emergency response shape

Exact schema may gain fields, but all clients must handle at least:

```json
{
  "id": "opaque-emergency-id",
  "category": "FALL_INJURY",
  "status": "ACTIVE",
  "createdAt": "2026-10-11T08:30:00.000Z",
  "updatedAt": "2026-10-11T08:30:00.000Z",
  "owner": { "id": "opaque-user-id", "displayName": "Example User" },
  "location": { "latitude": 21.1458, "longitude": 79.0882 },
  "approximateDistanceMeters": null,
  "assignedResponder": null,
  "escalation": { "isEscalated": false, "reason": null },
  "proof": { "status": "NOT_SUBMITTED", "transactionHash": null }
}
```

Fields are permission-filtered by the API. A responder's pre-acceptance representation should omit exact `location` and owner contact details and return an appropriately coarse location plus `approximateDistanceMeters`. The assigned responder's detail response may include exact coordinates after assignment is confirmed.

## 8. Socket.IO events

Canonical event names:

- `emergency.created`
- `emergency.updated`
- `responder.accepted`
- `responder.arrived`
- `emergency.resolved`
- `emergency.cancelled`

Payload envelope:

```json
{
  "eventId": "opaque-event-id",
  "occurredAt": "2026-10-11T08:30:00.000Z",
  "emergencyId": "opaque-emergency-id",
  "version": 1,
  "data": {}
}
```

Use authenticated, authorized user-specific or emergency-specific rooms. The server determines room membership. Never broadcast sensitive fields or exact coordinates globally. A socket event is a notification, not the source of truth: after reconnect or detecting a version gap, clients refetch the emergency by API. Push notifications via FCM complement sockets; a development fallback must be documented if FCM credentials are absent.

## 9. Matching and notification policy

- Initial search radius: `500 m`; then `1 km`; maximum `3 km`. Make values configurable.
- Expand the radius progressively on a bounded timer; document the cadence and stop conditions.
- Candidate must be `VERIFIED`, available, have a recent location, be within current radius, and match any capability requirements.
- Use a fair, deterministic candidate ordering for the MVP (for example distance first, then an explicit tie-break). Avoid silently using reputation as a safety guarantee.
- Do not repeatedly notify the same responder for the same emergency in a tight loop. Deduplicate notifications.
- Escalation can notify additional responders and show the user an explicit call action for public emergency services.
- Never claim that 112/108 was automatically contacted unless a real, authorized, tested integration exists. The default MVP must not pretend to contact those services.

## 10. Location and data privacy

- Exact coordinates are private personal data and stay off-chain.
- Before acceptance, responders see only coarse/approximate location and approximate distance.
- Reveal precise location only to the emergency owner and the assigned responder after server-confirmed assignment, subject to authorization.
- Limit location history retention; do not retain frequent location tracking when unnecessary.
- Do not put names, phone numbers, exact coordinates, medical information, chat, Aadhaar information, or other personal data in smart-contract storage, transaction calldata, event logs, or public transaction metadata.
- Do not put API tokens, keys, private keys, passwords, or signing secrets into source control.
- Hashes are not anonymization. Do not assume a hash makes guessable or low-entropy information safe.
- Log access to sensitive operations, but avoid logging full request bodies or coordinates.

## 11. Blockchain boundary

Blockchain is an audit/trust layer, not the runtime emergency dispatcher. The backend remains the source of truth for authentication, matching, assignment, state transitions, notifications, and private event history.

MVP contract responsibilities (may be implemented as three contracts or combined if time-constrained):

1. `ResponderRegistry`: authorized verifier can register, verify, and revoke opaque responder references and verification attestations.
2. `EmergencyLedger`: an authorized backend attestor can record a versioned, privacy-safe proof for selected milestones (especially arrival and resolution).
3. `Reputation`: maintain a limited, event-based reputation/completion record or emit attested events; do not expose a financial token or transfer rewards.

No cryptocurrency rewards, tradable tokens, NFTs, DAO, or on-chain medical data in the MVP. Real-world help is not proven merely by writing a transaction: proofs are only as trustworthy as the verifier/attestor, corroboration, and dispute process.

### Proof record minimum

- opaque `emergencyRef` (random, non-identifying; never a phone number or database content)
- opaque `responderRef`
- event type from a fixed enum, e.g. `RESPONDER_ARRIVED`, `EMERGENCY_RESOLVED`
- timestamp or coarse time value as agreed by the implementation
- `payloadHash` of a canonical, versioned record excluding sensitive fields
- event/version identifier to prevent accidental duplication

The backend writes the off-chain event first and queues blockchain submission asynchronously. Persist transaction state as `NOT_SUBMITTED`, `PENDING`, `CONFIRMED`, or `FAILED`, with retries and idempotency. Blockchain failure must not block the core emergency flow.

### Canonical hashing requirement

Before implementing hash generation, backend and blockchain agents must agree on one canonical encoding and publish test vectors. Recommended starting point: a versioned JSON record with a fixed key order, UTF-8 encoding, normalized UTC timestamp format, no insignificant whitespace, and explicitly specified hash algorithm (e.g. SHA-256). Do not independently invent serializers in multiple layers. Contract verification may store/compare a `bytes32` digest even if the off-chain digest is SHA-256; ensure the conversion is exact. Avoid ambiguous concatenation of fields.

## 12. Nonfunctional requirements

- Type-safe request/response DTOs and centralized validation.
- Password hashing; JWT expiry and protected routes.
- Server-side authorization for every private action.
- Atomic emergency assignment and idempotent resolution/proof submission.
- Structured logs with correlation/request IDs and no sensitive payloads.
- Unit tests for transitions, permissions, matching, privacy filtering, and hash test vectors.
- A working local demo with documented environment variables and seed/demo accounts.
- Provide useful loading, success, empty, offline, denied, and retry states in the UI.
- No Kafka, Kubernetes, microservices, or other infrastructure that is not necessary to prove the MVP.

## 13. Required repository deliverables

- Source code, not just a proposal or scaffold.
- `.env.example` containing placeholders only.
- README with setup, migrations/seeding, test, run, and demo instructions.
- OpenAPI specification matching the real routes and schemas.
- Tests for critical behavior.
- Smart-contract compile/test/deploy scripts and address configuration if using an EVM network.
- Documented known limitations, especially verification, public-service integration, and proof trust assumptions.

## 14. Contract change protocol

If a layer needs to change an endpoint, enum, state transition, event, hash field, or privacy rule:

1. Propose the exact change in the shared contract.
2. Update this file first (or a versioned successor).
3. Update affected layer documents and OpenAPI/event/hash test vectors.
4. Notify all agents and add a compatibility test.

Do not implement a local variant silently.
