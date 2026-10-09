# LibTrack — Staff Module (Flutter + Spring Boot)

A Flutter (Material 3) Staff Module for LibTrack, now wired to a real
Spring Boot backend (see the companion `libtrack_backend.zip`). Red
`#B71C1C` / white VVCE branding, 16px rounded cards, soft shadows, Riverpod +
GoRouter.

## What changed from the UI-only version

- **Login screen** (`lib/screens/auth/login_screen.dart`) — the app now
  requires staff credentials.
- **AuthGate** (`lib/screens/auth/auth_gate.dart`) — the root route (`/`).
  Shows the login screen if no JWT is cached, otherwise the bottom-nav
  `StaffShell` — no manual navigation needed after login, it just rebuilds.
- **`lib/services/`** — a Dio-based API client (`api_client.dart`) plus one
  service per domain (`auth_service.dart`, `book_service.dart`,
  `student_service.dart`, `transaction_service.dart`,
  `reservation_service.dart`, `notification_service.dart`,
  `report_service.dart`, `qr_service.dart`, `staff_service.dart`,
  `dashboard_service.dart`) — each method maps 1:1 to a backend endpoint.
- **`lib/providers/staff_providers.dart`** — every provider is now backed by
  a real network call (`FutureProvider` / `FutureProvider.family`) instead
  of mock data. Screens consume them with `.when(data:, loading:, error:)`.
- **Every screen** now calls its matching backend endpoint directly:
  Issue Book calls `POST /transactions/issue`, Return Book calls
  `POST /transactions/return` + `/collect-fine`, Reservations calls
  approve/cancel/notify, Reports exports real PDF/Excel bytes and shares
  them via `share_plus`, the QR Scanner looks up real books/students.

## Before you run it

1. Start the backend first (`libtrack_backend.zip` → `mvn spring-boot:run`).
2. Open `lib/services/api_client.dart` and set `baseUrl` to where that
   server is reachable:
   - Android emulator → `http://10.0.2.2:8080/api` (already the default)
   - iOS simulator → `http://localhost:8080/api`
   - Physical device → `http://<your-machine-LAN-IP>:8080/api`
3. `flutter pub get && flutter run`.
4. Log in with the seeded staff account: **username** `anitha.r`,
   **password** `staff123` (see the backend's `data.sql`).

## Endpoint ↔ screen map

See `libtrack_backend/README.md` for the full table — every screen's
buttons and lists are labeled with the exact method + path they call.

## Still mock / to wire up yourself

- **QR camera feed**: the scanner screen currently takes a typed code
  instead of a live camera scan. Swap the `TextField` in
  `qr_scanner_screen.dart` for `mobile_scanner`'s `MobileScanner` widget
  (already in `pubspec.yaml`) and feed its detected value into `_lookup()`.
- **Push notifications**: `firebase_messaging` is included but not
  initialized — wire up `Firebase.initializeApp()` and a background handler
  if you want live push delivery; the in-app Notifications screen already
  works against `/api/notifications`.
- **Edit Profile / Settings / Help & Support** tiles on the Profile screen
  are stubs (`onTap: () {}`) — `PUT /api/staff/me` is ready on the backend
  whenever you build that form.

## Architecture

```
lib/
  main.dart
  theme/app_theme.dart
  router/app_router.dart          # AuthGate at '/', full-screen routes for everything else
  models/models.dart              # fromJson factories matching backend DTOs
  services/                       # Dio calls — one file per backend controller
  providers/staff_providers.dart  # FutureProvider wrappers around services
  widgets/                        # Shared components (StatCard, BookCard, etc.)
  screens/auth/                   # LoginScreen, AuthGate
  screens/staff/                  # One file per screen (unchanged from the UI-only build)
```

## What's new in this revision

Fixes for the bugs you reported from testing:
- **Dashboard overflow** ("BOTTOM OVERFLOWED BY 12 PIXELS") — StatCard rebuilt to be compact and overflow-safe on any phone size.
- **Issue Book dropdown overflow** ("RIGHT OVERFLOWED BY 5.6 PIXELS") — added `isExpanded: true` so long book titles truncate instead of overflowing.
- **Empty dashboard/reservations/alerts** — backend `data.sql` now seeds sample active borrows, a reservation, and notifications so the app isn't blank on first run.
- **Dead Profile buttons** — Edit Profile, Change Password, Settings, Help & Support, Feedback, and Wishlist are all fully wired now, not stubs.

New features:
- **Dark Mode** — toggle in Profile → Settings. `AppColors` is now brightness-aware so every existing screen adapts automatically; persisted across launches.
- **Bottom nav restructured** to Home / Search / My Books / Profile (Transactions and Alerts tabs removed — notifications now live behind the bell icon on the Dashboard).
- **Extend Due Date** — on My Books, push a book's due date out instead of the student accruing a fine (`POST /api/transactions/{id}/extend`).
- **Profile photo** — Edit Profile lets staff pick a photo from their gallery (stored as base64 via `PUT /api/staff/me`).
- **Feedback** — submit and view feedback (`/api/feedback`).
- **Wishlist / Book Recommendations** — suggest titles for the library to acquire (`/api/recommendations`).
- **Library Timings** — static weekly hours screen (`/api/library/timings`).

## New dependencies

Run `flutter pub get` after unzipping — `image_picker` and `shared_preferences` were added.
