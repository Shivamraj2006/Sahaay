# Sahaay — Flutter Client Handoff

**Audience:** Flutter/frontend coding agent. Read `00-shared-contract.md` first; it is authoritative.

## 1. Scope

Build one Flutter app with elderly-user and responder modes selected from the authenticated account role. Keep the app approachable for older users: large touch targets, high contrast, simple language, readable typography, clear confirmation states, and no reliance on tiny icons alone.

Recommended stack: Flutter, Material 3, Riverpod, GoRouter, Dio, Socket.IO client, Geolocator, secure storage, and Firebase Cloud Messaging (FCM) if credentials are available. Use simple, maintainable feature-based structure; do not over-abstract the hackathon MVP.

## 2. Screens and primary flows

### Shared
- Welcome / sign-in / sign-up
- Loading, API error, offline, session-expired states
- Profile and sign-out
- Role-aware routing; prevent the user from navigating to screens/actions their role cannot use

### Elderly-user mode
- Home with one dominant **SOS** button and a visible note that Sahaay complements public emergency services
- Category choice: Medical emergency, Fall/injury, Hospital assistance; if the user taps SOS first, make category selection fast and accessible
- Short cancel countdown and obvious **Cancel SOS** action
- Active-emergency screen with clear status, whether a responder has been assigned, and safe escalation/call actions
- Assigned responder information only when authorized and available
- Resolution/cancellation confirmation and basic history

### Responder mode
- Availability toggle and verification state
- Nearby emergencies list/map with category, approximate distance, age of alert, and coarse location only
- Emergency detail prior to acceptance, without exact coordinates or unnecessary owner data
- Accept/decline action with pending state and clear handling if another responder wins
- Assigned emergency detail with exact location only after backend confirms assignment
- Arrived, resolve, or escalate actions according to server-validated transitions
- History and reputation/completed assistance summary; clearly distinguish on-chain proof status from real-world truth

### Verifier/Admin (minimal)
Admin tooling may be a lightweight screen or a documented API/demo flow if time is tight. Do not ship privileged admin actions to ordinary accounts.

## 3. API client rules

Use `/api/v1` and endpoint names/schemas in `00-shared-contract.md`. Do not hardcode a second API design. Centralize:

- Base URL and environment selection
- Bearer token attachment and session expiry handling
- JSON serialization/parsing
- API error mapping (`error.code`, `error.message`, `requestId`)
- Request timeout and safe retry behavior

Never automatically retry non-idempotent operations such as SOS creation or acceptance unless the backend supports an idempotency key. If idempotency keys are implemented, document the header/field and apply consistently.

## 4. State management

Use Riverpod providers/notifiers for authentication, user profile, active emergency, responder availability, nearby emergencies, and live socket connection. Keep domain models aligned with the shared enums:

- Categories: `MEDICAL`, `FALL_INJURY`, `HOSPITAL_ASSISTANCE`
- Emergency status: `ACTIVE`, `ASSIGNED`, `RESPONDER_ARRIVED`, `ESCALATED`, `RESOLVED`, `CANCELLED`
- Verification: `UNVERIFIED`, `PENDING`, `VERIFIED`, `REVOKED`

Do not derive authoritative status transitions locally. Update UI from server responses and refetch after reconnect. When an event appears stale or out of order, fetch the current emergency by API.

## 5. Location handling

- Request location permission with a clear explanation at the time it is needed.
- Handle denied, permanently denied, unavailable GPS, timeout, and stale location gracefully.
- Send user location only when the user initiates SOS or when the responder explicitly opts into availability and location sharing; explain the behavior.
- Send API coordinates as `{ "latitude": number, "longitude": number }`.
- Do not persist exact emergency coordinates in local analytics or general-purpose logs.
- Before assignment, render only coarse location/approximate distance. The client must never attempt to infer exact coordinates from an approximate value.
- Only display exact coordinates/navigation details after the server response authorizes them for the assigned responder.

## 6. SOS countdown and race conditions

The countdown is a usability safeguard, not an authoritative timer. On SOS:

1. Show an immediate, clear pending/countdown state.
2. Follow the agreed API timing: either create the emergency immediately as `ACTIVE` and allow cancellation during the countdown, or defer server creation until countdown completion. The team must choose one approach and document it in OpenAPI; do not let client and server assume different semantics. **Recommended MVP:** create immediately so the backend can begin its auditable flow, then cancel via API if the user cancels before dispatch proceeds.
3. Use the cancel endpoint; do not merely hide the screen.
4. Handle cancel/accept races using the server's authoritative response. If already assigned, clearly tell the user and show the available next action.

Never state that 112/108 has been called unless the backend provides a proven integration response. A user-triggered call action may open the phone dialer, and the UI should make the destination explicit.

## 7. Socket.IO and push

Listen to the canonical event names in the shared contract. Authenticate socket connections and join only permitted rooms using the backend protocol. Treat events as invalidation/update hints; the API remains the source of truth. On reconnect, refetch the current emergency and relevant list.

FCM may be unavailable in a local demo. Provide a documented fallback: in-app Socket.IO while foregrounded plus visible setup instructions for push. Do not show fake “push delivered” success states.

## 8. UX, accessibility, and resilience

- Use large, well-spaced controls and clear text labels; icons always have accessible labels.
- Do not encode status with color alone.
- Confirm dangerous actions such as cancellation where useful, but do not bury SOS under multi-step forms.
- Distinguish **request sent**, **responder assigned**, **responder arrived**, **escalated**, **resolved**, and **cancelled**.
- Show retry and connection states; avoid duplicate emergency creation during refresh/retry.
- Keep notes short and warn the user not to enter unnecessary sensitive details.

## 9. Frontend testing checklist

- Unit tests for DTO parsing and enum handling, including unknown enum fallback.
- Widget tests for SOS, countdown cancellation, and server conflict states.
- Responder acceptance losing a race returns to a safe screen and refreshes data.
- Pre-acceptance UI cannot reveal exact coordinates; post-assignment UI can show them only for the assigned responder.
- Socket reconnect triggers a refetch.
- Expired token, denied location permission, no network, empty nearby list, and API errors have understandable UI.
- Role-based navigation does not expose verifier/admin capabilities to normal accounts.

## 10. Environment and deliverables

Provide `.env.example` or documented Flutter `--dart-define` values for API URL and optional Firebase configuration. Include run commands, demo flow, tests, and known limitations in README. Do not commit real keys or credentials.
