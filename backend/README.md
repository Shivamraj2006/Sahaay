# Sahaay Backend

Community emergency-response backend for elderly people in urban India. Built with Node.js, TypeScript, Express, MongoDB, Socket.IO, and Zod.

## Quick Start

### Prerequisites
- Node.js 18+
- MongoDB (local or Atlas)
- npm

### Setup

```bash
# Install dependencies
npm install

# Copy environment config
cp .env.example .env
# Edit .env with your MongoDB URI and JWT secret (defaults provided for dev)

# Seed demo accounts
npm run seed

# Run automated tests
npm test

# Build production bundle
npm run build

# Start development server
npm run dev
```

### Demo Accounts (after seeding)

| Role | Phone | Password | Name | Notes |
|------|-------|----------|------|-------|
| Elderly User | `+919876543210` | `password123` | Kamla Devi | SOS creator |
| Verified Responder 1 | `+919876543211` | `password123` | Rahul Sharma | Nagpur center, available |
| Verified Responder 2 | `+919876543213` | `password123` | Amit Verma | For assignment race demos |
| Unverified Responder | `+919876543212` | `password123` | Priya Patel | Tests unverified exclusion |
| Admin / Verifier | `+919876543200` | `password123` | Admin User | Verifies/revokes responders |

## Testing

Run the full automated test suite with Vitest:

```bash
npm test
```

Includes 8 test suites covering:
1. **Canonical proof hashing & test vectors** (`tests/canonical.test.ts`)
2. **Matching engine & ~100m location coarsening** (`tests/matching.test.ts`)
3. **Zod validation schemas** (`tests/validation.test.ts`)
4. **State machine transitions & terminal status rules** (`tests/state-machine.test.ts`)
5. **JWT authentication & role-based authorization guards** (`tests/auth-middleware.test.ts`)
6. **Location privacy & standard error envelope** (`tests/api-privacy.test.ts`)
7. **Trust outbox failure isolation** (`tests/outbox-worker.test.ts`)
8. **Express app integration & OpenAPI endpoint** (`tests/api-integration.test.ts`)

## API Documentation & OpenAPI Specification

- OpenAPI 3.0 file: [`openapi.json`](file:///home/shivam/Projects/Sahay/backend/openapi.json)
- Live endpoint: `GET /api/v1/openapi.json`
- Base path: `/api/v1`

### Endpoints Overview

#### Auth
- `POST /api/v1/auth/register` — Register a new elderly user or responder (privilege escalation blocked)
- `POST /api/v1/auth/login` — Login with phone and password, returns JWT

#### Users
- `GET /api/v1/users/me` — Get current user profile
- `PATCH /api/v1/users/me` — Update display name

#### Responders
- `GET /api/v1/responders/me` — Get responder profile
- `PATCH /api/v1/responders/me/availability` — Toggle availability & update location
- `GET /api/v1/responders/me/history` — Paginated assistance history
- `GET /api/v1/responders/me/reputation` — Reputation score & completed count

#### Emergencies
- `POST /api/v1/emergencies` — Create SOS (rate-limited, starts matching)
- `GET /api/v1/emergencies/nearby` — Eligible active emergencies (responder-only, coarse location)
- `GET /api/v1/emergencies/:id` — Details (owner, assigned responder, or admin only)
- `POST /api/v1/emergencies/:id/cancel` — Cancel (owner only, ACTIVE only)
- `POST /api/v1/emergencies/:id/accept` — Accept assignment (atomic conditional update)
- `POST /api/v1/emergencies/:id/decline` — Decline notification
- `POST /api/v1/emergencies/:id/arrive` — Mark arrived (assigned responder only)
- `POST /api/v1/emergencies/:id/resolve` — Resolve with outcome (`ASSISTED`, `REFERRED_TO_EMERGENCY_SERVICES`, etc.)
- `POST /api/v1/emergencies/:id/escalate` — Escalate to public services / extra responders

#### Admin
- `GET /api/v1/admin/responders/pending` — List pending responder applications
- `POST /api/v1/admin/responders/:id/verify` — Verify responder profile (creates audit log)
- `POST /api/v1/admin/responders/:id/revoke` — Revoke verification

#### Health & OpenAPI
- `GET /api/v1/health` — Health check
- `GET /api/v1/openapi.json` — OpenAPI 3.0 specification

## Socket.IO Events

Connect with JWT in `auth.token` or Authorization header. Events use the canonical envelope format:

```json
{
  "eventId": "opaque-event-id",
  "occurredAt": "2026-10-11T08:30:00Z",
  "emergencyId": "opaque-emergency-id",
  "version": 1,
  "data": {}
}
```

Canonical events:
- `emergency.created`
- `emergency.updated`
- `responder.accepted`
- `responder.arrived`
- `emergency.resolved`
- `emergency.cancelled`

## Canonical Proof Hashing (Blockchain Integration)

Tamper-evident milestone proofs (e.g. `ARRIVED`, `RESOLVED`) are hashed using canonical UTF-8 JSON with sorted keys and normalized ISO 8601 UTC timestamps (no milliseconds). See [`src/modules/trust/test-vectors.ts`](file:///home/shivam/Projects/Sahay/backend/src/modules/trust/test-vectors.ts).

Blockchain submission is handled via an asynchronous in-process Outbox worker:
`NOT_SUBMITTED` → `PENDING` → `CONFIRMED` / `FAILED`.

## Key Architectural Invariants

- **Atomic assignment**: Uses conditional `findOneAndUpdate({ _id, status: 'ACTIVE', assignedResponderId: null })` to guarantee exactly one responder wins an assignment.
- **Location privacy**: Exact coordinates are kept strictly off-chain and hidden from pre-acceptance responders. Only coarsened coordinates (~100m grid) and approximate distance are exposed prior to server-confirmed assignment.
- **Asynchronous proof outbox**: Blockchain latency or RPC outages never block SOS creation, dispatch, or resolution.
- **Append-only event log**: Every state transition writes an immutable `EmergencyEvent` with versioning and correlation IDs.

## Known Limitations

- Mobile phone authentication uses password authentication for MVP (SMS OTP provider omitted for local dev).
- Blockchain integration provides Ethers.js integration boundary and simulated testnet hashes unless local/remote EVM RPC is provided.
- Sahaay complements emergency services; it does not replace 112, 108, police, or hospital emergency care.
