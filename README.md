# Sahaay (सहाय) — Frontend Flutter Application

Community emergency-response network for elderly people living alone in urban India. Built for hackathon delivery strictly according to **`00-shared-contract.md`** and **`01-flutter-client-contract.md`**.

---

## 🚀 Key Features Built

1. **Elderly User Experience:**
   - Dominant, high-contrast **SOS button** (220px circular touch target, 38pt bold typography).
   - Fast Category Picker: `MEDICAL` (Medical emergency), `FALL_INJURY` (Fall / Injury), `HOSPITAL_ASSISTANCE` (Hospital assistance).
   - Non-sensitive optional notes input (e.g. flat number).
   - Immediate **5-second cancellation countdown** window with clear cancel action.
   - Live Emergency tracking screen displaying server-verified status, assigned responder details (when dispatched), and direct dial button.
   - Non-blocking escalation action & official national helpline banner (`112` and `108` emergency dialer shortcuts).

2. **Responder Experience (Volunteers & Doctors):**
   - Verification status check (`VERIFIED`, `PENDING`, `UNVERIFIED`, `REVOKED`).
   - Duty toggle: Active / Offline availability dispatch switch (`PATCH /responders/me/availability`).
   - **Privacy Shield:** Nearby alerts feed returns only coarse grid location and approximate distance (`~450 m`, `~1.2 km`). Exact coordinates and elder contact details are hidden before assignment.
   - **Atomic Assignment & Race Handling:** Safely handles concurrent acceptance; displays friendly feedback if another responder accepted first (`409 Conflict`).
   - **Exact GPS Unlocking:** Displays exact coordinates and one-tap **Google Maps navigation** only *after* server confirms assignment.
   - Real-time workflow actions: **Mark Arrived** (`POST /emergencies/:id/arrive`) and **Resolve** with outcome dropdown (`ASSISTED`, `REFERRED_TO_EMERGENCY_SERVICES`, `NO_CONTACT`, `OTHER`).
   - Audit attestation tracker showing off-chain proof status (`NOT_SUBMITTED`, `PENDING`, `CONFIRMED`, `FAILED`) and transaction hash.

3. **Admin / Verifier Portal:**
   - Lightweight interface for officers (`VERIFIER` / `ADMIN`) to inspect pending responder applications and approve them.

4. **Architecture & Security:**
   - **State Management:** Riverpod (`StateNotifierProvider`).
   - **Routing:** Role-guarded GoRouter (`/auth`, `/elderly`, `/responder`, `/admin`).
   - **Network & Error Mapping:** Dio with bearer token injector, `401` automatic logout, and structured `ApiException` parser matching the shared contract (`error.code`, `error.message`, `requestId`).
   - **Real-Time Sync:** Socket.IO client listening to canonical events (`emergency.created`, `emergency.updated`, `responder.accepted`, `responder.arrived`, `emergency.resolved`, `emergency.cancelled`).
   - **Secure Storage:** Sensitive tokens and session info stored via `flutter_secure_storage`.

---

## 🛠 Project Structure

```
lib/
├── core/
│   ├── network/
│   │   ├── api_client.dart          # Dio client with Bearer auth & error parsing
│   │   ├── api_exception.dart       # Contract-conforming error model
│   │   ├── app_config.dart          # Compile-time / environment configurations
│   │   ├── location_service.dart    # Resilient GPS positioning
│   │   └── socket_service.dart      # Real-time Socket.IO room & event manager
│   ├── storage/
│   │   └── secure_storage_service.dart # Encrypted token & session manager
│   └── theme/
│       └── app_theme.dart           # High-contrast, elder-friendly Material 3 theme
├── features/
│   ├── auth/
│   │   ├── models/user_model.dart   # Role & verification models
│   │   ├── providers/auth_provider.dart
│   │   └── screens/auth_screen.dart # Sign-in, sign-up, and demo profile presets
│   ├── elderly/
│   │   ├── models/emergency_model.dart # Shared contract emergency model
│   │   ├── providers/elderly_emergency_provider.dart
│   │   └── screens/
│   │       ├── elderly_home_screen.dart # Large SOS button & categories
│   │       └── elderly_active_emergency_screen.dart # Live tracking & countdown
│   ├── responder/
│   │   ├── providers/responder_provider.dart
│   │   └── screens/
│   │       ├── responder_home_screen.dart # Coarse alerts feed & duty switch
│   │       └── responder_active_emergency_screen.dart # Navigation & resolution
│   └── admin/
│       └── screens/admin_verification_screen.dart
├── shared/
│   └── widgets/
│       ├── accessibility_notice_banner.dart
│       ├── emergency_hotline_banner.dart
│       └── emergency_status_badge.dart
└── main.dart
```

---

## 🏃 Setup & Run

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Configure Environment
Copy `.env.example` or pass `--dart-define` parameters:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1 --dart-define=SOCKET_BASE_URL=http://localhost:3000
```

### 3. Run Unit Tests
```bash
flutter test
```

---

## ⚡ Hackathon Demo Walkthrough

1. **Sign In as Elderly User:**
   - Tap the quick preset chip **"Elderly (Ramkrishna)"** on the login screen.
   - Select category `FALL_INJURY` and tap the red **SOS** button.
   - The app transitions to the active screen with a 5s cancel countdown.

2. **Open Responder View (Second device / window):**
   - Tap the quick preset chip **"Volunteer (Aarav)"** and log in.
   - Turn ON the **"Available for Dispatch"** switch.
   - You will see Ramkrishna's alert with approximate distance and coarse location.
   - Tap **"Accept SOS"**. The backend assigns the alert atomically.
   - Once assigned, exact coordinates and Google Maps navigation are unlocked.

3. **Arrival & Resolution:**
   - Tap **"Mark Arrived At Scene"**.
   - After helping the citizen, choose Outcome `ASSISTED` and tap **"Complete & Submit Resolution"**.
   - Notice the blockchain proof card reflect `PENDING` / `CONFIRMED` without blocking the UI.
