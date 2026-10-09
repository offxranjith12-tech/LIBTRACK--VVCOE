# LibTrack Backend — Staff Module APIs

Spring Boot 3.3 / Java 17 REST API backing the LibTrack Staff Module Flutter
app. JWT auth, MySQL + JPA, PDF/Excel export, QR lookup — one endpoint group
per screen in the frontend zip.

## Stack

Spring Web · Spring Data JPA · Spring Security (JWT, stateless) · MySQL ·
OpenPDF (PDF export) · Apache POI (Excel export) · ZXing (QR generation)

## Running it

1. Create a MySQL database (or let `createDatabaseIfNotExist=true` in
   `application.yml` do it) and adjust `spring.datasource.username/password`.
2. Set a real `libtrack.jwt.secret` (long random string) before deploying.
3. `mvn spring-boot:run` (or `mvn clean package && java -jar target/*.jar`).
4. `backup_data.sql` seeds the student/book catalog. The default staff login is
   seeded separately, in code, by `DefaultStaffSeeder.java` — it calls the
   app's actual `PasswordEncoder` bean to hash the password, so the seed can
   never drift out of sync with the encoder (a hand-typed hash previously
   caused login to fail). Seeded login:
   - **username:** `anitha.r`
   - **password:** `staff123`

   If you're upgrading an existing database that already has a broken
   staff row from before this fix, run this once:
   ```sql
   DELETE FROM staff WHERE username = 'anitha.r';
   ```
   Then restart the app — `DefaultStaffSeeder` will recreate the row with a
   correct hash on the next boot.

Server runs on `http://localhost:8080`. For a physical device / emulator,
point the Flutter app at your machine's LAN IP (Android emulator: use
`10.0.2.2` instead of `localhost`).

## Endpoint map (screen → API)

| Screen / Function | Method & Path | Notes |
|---|---|---|
| **Login** (new — see Flutter integration notes) | `POST /api/auth/login` | body `{username, password}` → `{token, staff}` |
| Profile → Change Password | `PUT /api/auth/change-password` | requires `Authorization: Bearer <token>` |
| **Dashboard** stat cards | `GET /api/dashboard/stats` | issuedToday / returnedToday / pendingReturns / activeBorrowers |
| **Search Books** | `GET /api/books/search?query=&category=&department=&author=&rack=&shelf=&availability=` | all params optional |
| **Book Details** | `GET /api/books/{id}` | |
| Book Details / QR Scanner | `GET /api/books/isbn/{isbn}` | |
| **Issue Book** — student search | `GET /api/students/search?query=` | matches name or regNo |
| Issue Book — student card | `GET /api/students/{regNo}` | borrow limit / current borrowed / fine |
| Issue Book — Confirm Issue | `POST /api/transactions/issue` | body `{studentRegNo, bookId, issueDate?, dueDate?}` |
| **Return Book** — active borrows list | `GET /api/transactions/active` | |
| Return Book — Return Book button | `POST /api/transactions/return` | body: one of `transactionId` / `studentRegNo` / `bookIsbn` / `bookQrCode` |
| Return Book — Collect Fine | `POST /api/transactions/{id}/collect-fine` | |
| **Reservations** list | `GET /api/reservations` | |
| Reservations — Approve | `POST /api/reservations/{id}/approve` | |
| Reservations — Cancel | `POST /api/reservations/{id}/cancel` | |
| Reservations — Notify Student | `POST /api/reservations/{id}/notify` | |
| **Student Information** | `GET /api/students/{regNo}/details` | profile + borrowed books + reservation history |
| **Reports** overview | `GET /api/reports/summary` | |
| Reports — Export PDF | `GET /api/reports/export/pdf` | returns `application/pdf` bytes |
| Reports — Export Excel | `GET /api/reports/export/excel` | returns `.xlsx` bytes |
| **QR Scanner** — Book QR | `GET /api/qr/lookup/book/{code}` | code = ISBN or bookId |
| QR Scanner — Student ID QR | `GET /api/qr/lookup/student/{code}` | code = regNo |
| QR image (Book Details / receipts) | `GET /api/qr/generate?content=&size=300` | returns PNG bytes |
| **Notifications** list | `GET /api/notifications` | |
| Notifications — mark one read | `POST /api/notifications/{id}/read` | |
| Notifications — mark all read | `POST /api/notifications/read-all` | |
| **Profile** | `GET /api/staff/me` | |
| Profile — Edit Profile | `PUT /api/staff/me` | |

Every endpoint except `/api/auth/**` requires `Authorization: Bearer <token>`.

## Data model

```
Staff (login + profile)
Student (regNo PK)
Book (bookId PK, isbn unique)
BorrowTransaction (book ↔ student, status ACTIVE/RETURNED, fine)
Reservation (book ↔ student, status WAITING/AVAILABLE/APPROVED/CANCELLED)
LibNotification (type DUE_DATE/RESERVATION/OVERDUE/ANNOUNCEMENT/NEW_ARRIVAL)
```

Business rules enforced server-side:
- **Issue**: blocked if the book has 0 available copies, or the student has
  hit their `borrowLimit`. Decrements `availableCopies`, increments
  `currentBorrowed`.
- **Return**: fine = `daysOverdue × libtrack.fine.per-day-rupees` (default
  ₹5/day, configurable in `application.yml`). Increments `availableCopies`,
  decrements `currentBorrowed`, adds fine to `student.fineDue`.
- **Collect Fine**: subtracts the transaction's fine from `student.fineDue`
  and marks it collected (idempotent).
- **Reservation approval**: only allowed once status is `AVAILABLE`.

## Wiring this into the Flutter app

The Flutter zip's `staff_providers.dart` currently returns mock data. Replace
it with the `lib/services/*.dart` files (Dio-based, JWT-aware) — see the
updated Flutter zip / integration notes delivered alongside this backend.
The route shapes and screen widgets don't change; only the data source does.

## Security notes before production

- Replace the placeholder `libtrack.jwt.secret` with a securely generated
  secret kept out of source control (env var / secrets manager).
- Restrict CORS `allowedOriginPatterns` in `SecurityConfig` to your actual
  app origins instead of `*`.
- Add refresh-token support if you want sessions to outlive the 24h token
  expiry without re-login.
- Consider rate-limiting `/api/auth/login`.

## New in this revision

| Feature | Endpoint |
|---|---|
| Extend Due Date | `POST /api/transactions/{id}/extend` — body `{newDueDate}` |
| Feedback | `POST /api/feedback`, `GET /api/feedback` |
| Wishlist / Recommendations | `POST /api/recommendations`, `GET /api/recommendations` |
| Library Timings | `GET /api/library/timings` |

`Staff.photoUrl` is now `LONGTEXT` to store base64-encoded profile pictures.
`backup_data.sql` seeds sample active borrows, a reservation, and 4 notifications so the app has realistic data on first run instead of all-zero stats and empty lists.
