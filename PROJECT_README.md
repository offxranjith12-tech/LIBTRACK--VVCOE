# LibTrack — Student Module

Two parts in this zip:

```
libtrack_app/    -> Flutter mobile app (student module)
backend/          -> Spring Boot + MySQL 8 REST API
```

## Quick start

1. **Run the Flutter app as-is first** (no setup needed) — it runs on
   realistic built-in demo data (`useMockData = true`), so you can see
   everything working immediately:
   ```
   cd libtrack_app
   flutter clean
   flutter pub get
   flutter run
   ```

2. **When you're ready to connect the real backend**, follow
   `backend/libtrack-backend/README.md` to start the Spring Boot server
   against MySQL 8, then in `libtrack_app/lib/services/api_service.dart`
   flip:
   ```dart
   final bool useMockData = false;
   ```
   and set `baseUrl` to point at your server. Full details are in that
   README, including the emulator-vs-physical-device IP address note.

## What changed in this update

**Frontend (Flutter) — real backend wiring**
- Every screen (Dashboard, Search, My Books, Reservations, Notifications)
  now genuinely calls the Spring Boot API instead of silently reading
  local mock data
- Renew, Reserve, Cancel Reservation, Mark Notification Read all now hit
  the real backend and update MySQL
- A connection status banner on the Dashboard shows clearly whether the
  backend call succeeded or failed (with the real error message) - no
  more silent failures
- **A real Login screen** - the app now starts at Login, calls
  `/api/auth/login`, and stays logged in across restarts (checks the
  stored token at startup)
- **Real Logout** - clears the token and returns to the Login screen,
  from both Profile and the new Settings screen, with a confirmation dialog
- **Real Settings screen** - Dark Mode and notification-preference toggles
  that persist on-device, plus Change Password and Logout
- **Real Change Password screen** - calls the backend, validates the
  current password server-side
- **Real Wishlist** - tap the heart icon on any book (Search or Book
  Details) to save it; view saved books on a dedicated Wishlist screen;
  persists across restarts
- **Real Help & FAQ screen** with genuinely useful expandable Q&A content
- **Real Feedback Form** - category + message, submitted to the backend
  and stored in the database
- Edit Profile (name, email, phone, photo) saves to the database via
  `PUT /api/students/{id}` and the photo upload endpoint

**Earlier fixes (still included)**
- Fixed the dashboard overview cards permanently — fixed-height grid +
  auto-shrinking text, cannot overflow regardless of screen or font size
- Fixed Profile page alignment — label-above-value layout
- Replaced plain-text dashboard stats with an actual bar chart (fl_chart)
- Added a dedicated "Regulation Books" quick-filter chip on Search, plus
  6 Regulation-syllabus textbooks
- Fully responsive layout (phone / tablet / laptop)
- Removed the QR Scanner feature and its dependency

**Backend (Spring Boot + MySQL 8)**
- Full REST API: students, books (search/filter incl. Regulation),
  borrow/return/renew, reservations, notifications, dashboard stats,
  password change, feedback
- MySQL 8 via Spring Data JPA, auto-created schema, no manual SQL needed
- Profile photo upload endpoint (multipart, saved + served back as a URL)
- Demo data seeded automatically on first run
- Tiered fine logic (₹5/day overdue), 14-day loan period, max 2 renewals

## A note on the backend auth

Login is intentionally simple (checks the database, returns an opaque
token) so the whole thing runs with zero extra setup for a college
project/demo. It is **not** hardened for production (no password hashing,
no verified JWT). See "Hardening for real use" in
`backend/libtrack-backend/README.md` if you ever need to deploy this
somewhere beyond an assignment/demo.
