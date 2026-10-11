# Sahaay — Cross-Layer Integration and Demo Checklist

Use this checklist to coordinate agents and confirm the MVP works as one system. Read `00-shared-contract.md` as the source of truth.

## 1. Before parallel work begins

- [ ] All agents read `00-shared-contract.md`.
- [ ] Agree on the SOS countdown semantics. Recommended: create an `ACTIVE` emergency immediately, allow cancellation while active, then let backend dispatch proceed.
- [ ] Backend publishes an OpenAPI file that matches implemented routes and response schemas.
- [ ] Agree on canonical location filtering and which response fields differ by actor.
- [ ] Agree on exact Socket.IO payload envelope, authentication method, and authorized room names.
- [ ] Backend and blockchain agents freeze canonical proof fields, encoding, hash algorithm, and shared test vectors before integration.
- [ ] Choose local-only demo accounts and ensure no real personal information is used.

## 2. Contract compatibility checks

- [ ] Category values exactly match: `MEDICAL`, `FALL_INJURY`, `HOSPITAL_ASSISTANCE`.
- [ ] Emergency states exactly match the shared list and transitions are server-owned.
- [ ] Verification states exactly match: `UNVERIFIED`, `PENDING`, `VERIFIED`, `REVOKED`.
- [ ] Proof statuses exactly match: `NOT_SUBMITTED`, `PENDING`, `CONFIRMED`, `FAILED`.
- [ ] All API paths start with `/api/v1` and match the shared route list/OpenAPI.
- [ ] Timestamps use normalized ISO 8601 UTC strings.
- [ ] API locations use `{ latitude, longitude }`; GeoJSON storage uses `[longitude, latitude]`.
- [ ] Socket event names and envelopes match the shared contract.
- [ ] Frontend does not implement state transitions that the backend has not accepted.

## 3. Security and privacy acceptance tests

- [ ] A non-owner cannot read another user's emergency.
- [ ] An unverified, revoked, unavailable, stale-location, or incompatible responder cannot accept an emergency.
- [ ] Two responders attempt acceptance at the same time; exactly one is assigned.
- [ ] A responder cannot mark arrived or resolve an emergency assigned to someone else.
- [ ] Admin/verification routes reject normal user roles.
- [ ] Nearby results contain coarse location/approximate distance, not exact coordinates or unnecessary contact details.
- [ ] Assigned responder receives exact location only after assignment is confirmed by backend.
- [ ] Socket room membership is authorized and payloads are recipient-filtered.
- [ ] Chain calldata/events have no names, phones, exact coordinates, medical details, Aadhaar information, or other personal data.
- [ ] Source control contains no real secrets, passwords, API tokens, RPC keys, or production user data.

## 4. End-to-end demo script

1. Start MongoDB and the backend; seed one elderly account and at least two responder accounts. One responder is `VERIFIED` and available; optionally seed another ineligible responder to demonstrate filtering.
2. Start the local EVM chain and deploy contracts, if blockchain demo is configured. Grant the backend attestor role.
3. Start the Flutter app (or two app instances). Sign in as the elderly user and verified responder.
4. Toggle responder availability on.
5. From elderly mode, create an SOS with a category and test location.
6. Confirm the user sees `ACTIVE` and an authorized responder receives an alert with coarse location only.
7. Accept from the responder. Confirm the API/database assigns exactly one responder and only then returns exact coordinates to that responder.
8. Attempt acceptance from the second responder; confirm a conflict/expired-offer state and no duplicate assignment.
9. Mark arrived. Confirm `RESPONDER_ARRIVED`, persisted event history, and a proof outbox item.
10. Resolve or escalate. Confirm authoritative status, appropriate notifications, and no sensitive data leakage.
11. If blockchain is configured, wait for proof receipt and confirm proof status changes to `CONFIRMED`; if RPC fails, confirm emergency workflow still succeeds and status becomes `FAILED` or remains pending for retry.
12. Test cancellation from the elderly account and the cancellation-versus-acceptance race.
13. Show history/reputation as a summary of completed assistance. State clearly that chain transactions prove submitted attestations, not that on-chain code independently verifies a real-world rescue.

## 5. Failure cases that must be visible and safe

- Location permission denied or GPS unavailable
- No eligible responders within 3 km
- Socket disconnect/reconnect
- FCM credentials missing
- Responder offer becomes unavailable because another responder accepted
- SOS cancellation races with accept
- API server unavailable / expired authentication
- Blockchain RPC unavailable, transaction reverted, or receipt delayed
- Responder verification revoked after being approved

The UI must not imply emergency services have been contacted automatically. When no responder is found or the situation is urgent, present explicit user-triggered options to contact appropriate public emergency services.

## 6. Definition of done

- [ ] A clean clone can be configured using documented commands.
- [ ] README and `.env.example` are present and accurate.
- [ ] Critical unit/integration tests pass.
- [ ] Flutter client talks to the actual API; no fake local-only success is presented as backend success.
- [ ] Backend is authoritative for authorization, matching, state, and exact-location release.
- [ ] Blockchain proof submission is asynchronous and cannot block emergency actions.
- [ ] OpenAPI, Socket.IO schemas, and hash test vectors are checked in.
- [ ] Known limitations and the boundary with 112/108 are clearly documented.
