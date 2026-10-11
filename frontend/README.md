# Sahaay Mobile Application (Flutter)

A community emergency-response mobile client for elderly people living alone in urban India. Built with Flutter, Material 3, and styled following the verified **Stitch App Design** (Project ID: `10716582699195818378`, Screen ID: `fd61c5bdbc0b4829aeb521c8b2852884`).

---

## 🎨 Implemented Stitch Design Screens

The application faithfully implements all 6 core screens and interaction flows from the Stitch design specifications:

| # | Screen | Implementation Path | Stitch Visual Details |
|---|---|---|---|
| **1** | **Home Screen** | [`lib/screens/elderly/elderly_home_screen.dart`](file:///home/shivam/Projects/Sahay/frontend/lib/screens/elderly/elderly_home_screen.dart) | Greeting header ("Good morning, Amma 👋"), senior avatar with green online badge, central concentric glowing pulse rings with giant red SOS button (`#EF4444`), 3 emergency category cards (Medical, Fall/Injury, Need Hospital), Emergency Contacts summary card, and 4-tab bottom navigation bar. |
| **2** | **SOS Countdown Overlay** | [`lib/screens/elderly/sos_countdown_dialog.dart`](file:///home/shivam/Projects/Sahay/frontend/lib/screens/elderly/sos_countdown_dialog.dart) | 3-second animated circular progress indicator ring with countdown digits (3, 2, 1), disclaimer text, and prominent "Cancel SOS" action. |
| **3** | **SOS Sent Confirmation** | [`lib/screens/elderly/sos_sent_screen.dart`](file:///home/shivam/Projects/Sahay/frontend/lib/screens/elderly/sos_sent_screen.dart) | Emerald checkmark badge, "SOS Sent - Help is on the way!", incident details card with sent timestamp, pulsating live beacon at Koramangala Bengaluru, notified contacts, "Cancel SOS" pill button, and direct "Call 108 (Ambulance)" CTA. |
| **4** | **Emergency Contacts List** | [`lib/screens/elderly/contacts_screen.dart`](file:///home/shivam/Projects/Sahay/frontend/lib/screens/elderly/contacts_screen.dart) | Header with "+" trigger, contact cards for Ramesh Kumar (Son), Lakshmi (Daughter), and Dr. Meera Iyer (Family Doctor) with quick dial buttons and "+ Add Emergency Contact" bottom CTA. |
| **5** | **Add Emergency Contact** | [`lib/screens/elderly/add_contact_dialog.dart`](file:///home/shivam/Projects/Sahay/frontend/lib/screens/elderly/add_contact_dialog.dart) | Modal form with Name, Relationship dropdown (Son, Daughter, Spouse, Family Doctor, Neighbor, Caregiver), Phone number with +91 country prefix badge, and "Save Contact". |
| **6** | **Contact Options Sheet** | [`lib/widgets/contact_options_sheet.dart`](file:///home/shivam/Projects/Sahay/frontend/lib/widgets/contact_options_sheet.dart) | Modal bottom sheet with avatar preview, Call option, Edit option, Remove option (red highlight), and Cancel button. |

---

## 🚀 Dual Mode Architecture (Elderly & Responder)

In alignment with [`Plan/01-flutter-client-contract.md`](file:///home/shivam/Projects/Sahay/Plan/01-flutter-client-contract.md):

1. **Elderly User Mode (`ELDERLY_USER`)**:
   - Dominant SOS button with high-contrast accessibility.
   - Quick category selection (`MEDICAL`, `FALL_INJURY`, `HOSPITAL_ASSISTANCE`).
   - Live rescue tracking (shows assigned volunteer name, arrival on scene, and resolution).
2. **Volunteer Responder Mode (`VOLUNTEER`)**:
   - Duty availability toggle switch (`available = true/false`).
   - Verified responder badge linked to the on-chain [`ResponderRegistry.sol`](file:///home/shivam/Projects/Sahay/blockchain/contracts/ResponderRegistry.sol).
   - Feed of nearby incidents within 3 km with **~100m coarse location** and approximate distance.
   - **Post-assignment privacy unlock**: Exact GPS coordinates and resident address are revealed only after assignment is atomically confirmed.
   - Milestone triggers: Mark Arrived, Resolve with outcome (`ASSISTED`, `REFERRED_TO_EMERGENCY_SERVICES`), and view the on-chain audit proof.

---

## 💻 Quick Start & Running

### Prerequisites
- Flutter SDK (3.19.0+)
- Dart (3.3.0+)
- Node.js backend (optional; the app has instant offline/demo fallback mode)

### 1. Install Dependencies
```bash
cd frontend
flutter pub get
```

### 2. Run Automated Unit Tests
```bash
flutter test
```

### 3. Launch App
```bash
# Run on Chrome / Web (with responsive mobile device frame)
flutter run -d chrome

# Run on connected Android device or emulator
flutter run -d android
```

---

## 👥 Seed Demo Personas

Switch between personas dynamically from **Settings $\to$ Switch Active Persona**:

| Persona | Role | Credentials | Location |
|---|---|---|---|
| **Kamla Devi (Amma)** | Elderly User | `+919876543210` / `password123` | Koramangala, Bengaluru (SOS Creator) |
| **Rahul Sharma** | Volunteer Responder | `+919876543211` / `password123` | Verified Volunteer (~350m away) |
| **Amit Verma** | Volunteer Responder | `+919876543213` / `password123` | Verified Volunteer (Secondary) |
| **Admin User** | Admin / Verifier | `+919876543200` / `password123` | Verifier & Attestor |
