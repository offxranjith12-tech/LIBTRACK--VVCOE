# LibTrack — Admin Module (Flutter)

Library Management System for **V V College of Engineering**.
This package contains the complete, production-ready **Admin** module — dashboard,
book management, user management, issue/return workflows, reservations, QR code
tools, reports & analytics, notifications, and system settings.

## ✨ Stack

| Layer            | Choice                                   |
|-------------------|-------------------------------------------|
| UI                | Flutter, Material 3                       |
| State management  | Riverpod (`flutter_riverpod`)             |
| Navigation        | `go_router`                               |
| Backend           | Spring Boot REST API (JWT auth)           |
| Networking        | `dio` (`lib/core/network/api_client.dart`)|
| QR                | `mobile_scanner` (scan), `qr_flutter` (generate) |
| PDF export        | `pdf` + `printing`                        |
| Charts            | `fl_chart`                                |
| Push notifications| `firebase_messaging` + `flutter_local_notifications` |

## 🎨 Brand

- Primary: `#B71C1C`  •  Secondary: `#D32F2F`
- Background: `#F8F9FA`  •  Cards: white, 16px radius, soft shadow
- Full light & dark Material 3 themes in `lib/core/theme/app_theme.dart`

## 📁 Project structure

```
lib/
├── core/
│   ├── constants/       # colors, app-wide constants (depts, categories, fine rules)
│   ├── theme/           # Material 3 light/dark theme
│   ├── router/          # go_router route table
│   ├── network/         # ApiClient (Dio+JWT), AuthService, PdfService, PushNotificationService
│   └── mock/            # realistic demo data (works fully offline)
├── models/               # Book, Student, Staff, LibraryTransaction, Reservation,
│                         # LibNotification, AdminProfile
├── providers/            # Riverpod StateNotifiers + derived providers
│   ├── book_provider.dart
│   ├── user_provider.dart
│   ├── transaction_provider.dart   # issue/return + DashboardStats aggregator
│   ├── notification_provider.dart
│   └── theme_provider.dart
├── widgets/               # StatCard, QuickActionButton, BookCard, SectionHeader,
│                         # AppSearchField, StatusBadge, AppShell (bottom nav)
├── screens/
│   ├── auth/             # LoginScreen
│   ├── dashboard/        # DashboardScreen
│   ├── books/            # List, Detail, Add/Edit
│   ├── users/            # Students/Staff tabs
│   ├── transactions/     # Issue, Return, full transaction log
│   ├── reservations/     # Approve/reject queue
│   ├── reports/          # Charts + PDF/Excel/CSV export menu
│   ├── qr/               # Generate/print + live scanner
│   ├── notifications/    # Inbox + compose/send
│   ├── settings/         # System settings
│   └── profile/          # Admin profile
└── main.dart
```

## 🔌 Backend connection status

**Books are fully live** against the real Spring Boot + MySQL backend
(see `../libtrack-backend`):
- Book search (`/books/search`), Add/Edit/Delete, and Bulk Import all call
  the real API — no mock data involved for books.
- Login calls the real `/auth/login` and stores the JWT.

**Still using local mock data** (`lib/core/mock/mock_data.dart`) for now:
Students, Staff, Transactions (issue/return), Reservations, Reports,
Notifications, QR. The backend already exposes matching REST endpoints for
these (`/students`, `/staff`, `/transactions/*`, `/dashboard/stats`) — wiring
them up follows the exact same pattern used for books:
1. Add a `*RemoteService` in `lib/core/network/` (copy `book_remote_service.dart`)
2. Add a provider in `lib/providers/service_providers.dart`
3. Swap the screen's `ref.watch(xProvider)` (mock) for a call to the new service

Set `AppConstants.baseUrl` in `lib/core/constants/app_constants.dart` to
point at your running backend:
- Android emulator → host machine: `http://10.0.2.2:8080/api/v1`
- Physical phone, same WiFi as your computer: `http://<your-LAN-IP>:8080/api/v1`
- Production: your real HTTPS domain

## 🚀 Running the app

```bash
flutter pub get
flutter run
```

Start the backend first (`../libtrack-backend`, `docker compose up --build`),
then log in with the seeded admin credentials from its `.env` file. Book
search, add/edit/delete, and bulk import all hit that live server. Login
will show a clear error if the backend isn't reachable rather than silently
falling back to demo data.

## 🔌 Connecting the real backend

Already done for the book module — see above. To finish the rest, follow
the same three-step pattern for students, staff, transactions, and reports
described in "Backend connection status" above.

## 🔔 Push notifications

Firebase is not auto-initialized (it needs your project's
`google-services.json` / `GoogleService-Info.plist`). Steps are documented in
`lib/core/network/push_notification_service.dart`:

```bash
flutterfire configure
```

Then uncomment the `Firebase.initializeApp()` call in `main()` and the FCM
listener in `PushNotificationService.init()`.

## 🌗 Dark mode

Toggle from **Profile → System Settings → Appearance**, or programmatically:

```dart
ref.read(themeModeProvider.notifier).toggle();
```

## 📦 Notes

- Android/iOS native project folders are not included in this package — run
  `flutter create .` inside this directory once to generate them (this wires
  up the existing `lib/`, `pubspec.yaml`, and `assets/` automatically without
  overwriting your code).
- Replace the placeholder Poppins usage — the theme currently pulls
  `google_fonts` at runtime (no font files needed to ship).

## What's New in This Update

- **Mobile overflow fixes** — the Dashboard stat cards and the Books filter-
  chip row no longer throw `RenderFlex overflowed` errors on narrow phones.
- **Regulation field** — added to Book add/edit, search, and filtering;
  Floor Number and the QR-code input box were removed from the add/edit form
  (QR codes are still auto-generated server-side and shown on the detail/QR
  screens).
- **User Management** — real "Add Student" and "Add Staff / Librarian"
  screens, backend-wired. College email domain (`@vvcoe.org`) is validated
  both client-side and server-side; personal Gmail addresses are rejected.
  Toggle between Staff and Librarian when adding a staff account.
- **Reports** — the "books available / issued / fine collected" counters
  were removed; the screen now shows the report visualizations plus a real
  CSV download pulled live from the backend.
- **Notifications** — rebuilt as broadcast-only (All Students / All Staff /
  Everyone) — there's no "Individual" option anymore — fully backend-wired.
- **Settings** — Library Timing (opening/closing time, working days),
  Borrowing & Reservation Rules (limits, fine/day, extension days), a
  Feedback inbox, and a Pending Extension Requests queue with approve/reject
  — all backend-wired.
- **Transactions** — admin can mark a fine Paid/Unpaid/Waived and manually
  correct a transaction's status directly from the transaction list.
- **Profile** — Edit Profile and Change Password now hit the real
  `/api/v1/me` endpoints; Logout clears the stored JWT (not just navigation).
- **Dark Mode** — now applies across every screen (cards, text, dividers),
  not just the Scaffold background. See `core/constants/app_colors.dart` —
  `AppColors.card/background/text/textSecondary/divider` are dynamic getters
  driven by `AppColors.isDark`, synced once per frame from `main.dart`.

### Still on local mock data
Issue Book, Return Book, and Reservations screens still use in-memory mock
data (consistent with how this project was originally scoped — see the Book
module for the reference pattern to wire them to the real backend next).
