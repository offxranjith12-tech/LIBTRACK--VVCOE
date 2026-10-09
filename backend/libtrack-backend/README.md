# LibTrack Backend (Spring Boot + MySQL 8)

REST API backend for the LibTrack student module, matching the endpoints
the Flutter app's `lib/services/api_service.dart` already expects.

## What's included

- Spring Boot 3.2 (Java 17), Spring Web, Spring Data JPA
- MySQL 8 via `mysql-connector-j`
- Auto-created schema (Hibernate `ddl-auto=update` — no manual SQL needed)
- Demo data seeded automatically on first run: 1 student (Vignesh R,
  23CS086, password `password123`), 11 books (including 6 "Regulation"
  textbooks), 2 active borrows, 1 borrow history record, 1 reservation,
  3 notifications
- Profile photo upload (multipart) saved to an `/uploads` folder and
  served back as a URL
- Password change endpoint (validates the current password server-side)
- Feedback submission endpoint (category + message, tied to the student)
- No Spring Security / JWT verification is wired in — login just checks
  the DB and hands back a token so the demo has zero extra setup. See
  "Hardening for real use" below before deploying this anywhere public.

## 1. Install prerequisites

- JDK 17+
- Maven 3.8+ (or use your IDE's bundled Maven)
- MySQL 8 Server, running locally

## 2. Configure the database connection

Open `src/main/resources/application.properties` and set your MySQL
username/password:

```properties
spring.datasource.username=root
spring.datasource.password=root
```

You do **not** need to manually create the `libtrack_db` schema — it's
created automatically (`createDatabaseIfNotExist=true`) the first time you
run the app, and tables are created automatically from the JPA entities.

## 3. Run it

From this folder (`backend/libtrack-backend`):

```bash
mvn spring-boot:run
```

Or in IntelliJ / Eclipse / VS Code: open this folder as a Maven project
and run `LibtrackApplication.java`.

The API will be live at `http://localhost:8080/api`.

On first run you'll see log lines from Hibernate creating tables, then the
seeder inserts the demo data. Check it worked:

```bash
curl http://localhost:8080/api/students/1
curl http://localhost:8080/api/books
```

## 4. Point the Flutter app at it

In `lib/services/api_service.dart`, the `baseUrl` defaults to
`http://10.0.2.2:8080/api` — that's the special address the **Android
emulator** uses to reach your computer's `localhost`. Options:

- **Android emulator**: leave it as-is.
- **Physical Android phone**: replace it with your computer's LAN IP,
  e.g. `http://192.168.1.5:8080/api` (find it with `ipconfig` on Windows).
  Your phone and computer must be on the same Wi-Fi network.
- **iOS simulator / Chrome**: `http://localhost:8080/api` works directly.

Then flip the flag in the same file:

```dart
final bool useMockData = false; // was true
```

That's it — every screen backed by `ApiService` (dashboard stats, book
search, borrowed books, reservations, notifications, profile) will now
read/write through this backend and MySQL instead of the in-memory mock
data.

## API reference

| Method | Path                                   | Purpose                        |
|--------|-----------------------------------------|---------------------------------|
| POST   | `/api/auth/login`                       | Login (registerNumber, password) |
| GET    | `/api/students/{id}`                    | Get student profile             |
| PUT    | `/api/students/{id}`                    | Update name/email/phone         |
| POST   | `/api/students/{id}/profile-image`      | Upload profile photo (multipart)|
| PUT    | `/api/students/{id}/password`           | Change password                 |
| GET    | `/api/books?query=&category=&department=&author=&rack=&availability=` | Search/filter books |
| GET    | `/api/books/{id}`                       | Get one book                    |
| POST   | `/api/borrow`                           | Issue a book (studentId, bookId)|
| GET    | `/api/students/{id}/borrowed-books`     | List a student's borrowed books |
| POST   | `/api/borrowed-books/{id}/renew`        | Renew a borrow (max 2 renewals) |
| POST   | `/api/borrowed-books/{id}/return`       | Return a book                   |
| GET    | `/api/students/{id}/reservations`       | List a student's reservations   |
| POST   | `/api/reservations`                     | Reserve a book (studentId, bookId)|
| DELETE | `/api/reservations/{id}`                | Cancel a reservation            |
| GET    | `/api/students/{id}/notifications`      | List notifications              |
| PUT    | `/api/notifications/{id}/read`          | Mark a notification as read     |
| GET    | `/api/students/{id}/dashboard-stats`    | Dashboard chart/summary numbers |
| POST   | `/api/feedback`                         | Submit feedback (studentId, category, message) |
| GET    | `/api/students/{id}/feedback`           | List a student's submitted feedback |

## Business rules implemented

- Loan period: 14 days from borrow date
- Fine: ₹5/day once overdue, recalculated automatically whenever a
  student's records are read
- Renewals: up to 2 per borrow, blocked once the limit is reached
- Reservation queue position is computed per-book automatically

## Hardening for real use

This is intentionally kept simple for an academic project so it runs with
zero extra setup. Before using it beyond a demo/assignment:

1. Add Spring Security + real JWT verification (the login endpoint
   already returns a token shape the Flutter app expects).
2. Hash passwords (e.g. BCrypt) instead of storing them in plain text.
3. Restrict the CORS origin list in `config/WebConfig.java` instead of
   `allowedOriginPatterns("*")`.
4. Move the MySQL password out of `application.properties` and into an
   environment variable.

## Troubleshooting

- **"Communications link failure" / can't connect to MySQL** — make sure
  MySQL Server is running and the username/password in
  `application.properties` are correct.
- **Port 8080 already in use** — change `server.port` in
  `application.properties`, and update the Flutter `baseUrl` to match.
- **Flutter app can't reach the API from a physical phone** — double
  check both devices are on the same network, and that your firewall
  allows inbound connections on port 8080.
