# LibTrack Backend

Spring Boot 3 + MySQL REST API for the LibTrack Library Management System
(V V College of Engineering). JWT-secured, with a chunked-batch Excel/CSV
bulk importer built to handle 9,000–10,000+ book rows in one request.

## Stack

- Java 17, Spring Boot 3.3
- Spring Data JPA + MySQL 8
- Spring Security + JWT (`jjwt`)
- Apache POI (Excel) + Apache Commons CSV
- Docker / docker-compose

## Quick start (Docker — recommended)

```bash
cp .env.example .env
# edit .env: set a real DB password, JWT secret, and admin password

docker compose up --build
```

That's it. This starts:
- **MySQL 8** on port `3306`, with a persisted volume
- **The backend** on port `8080`, which auto-creates all tables on first boot
  and seeds one default admin account (credentials come from `.env`)

Check it's alive:
```bash
curl http://localhost:8080/actuator/health
```

Swagger UI (interactive API docs): `http://localhost:8080/swagger-ui.html`

## Quick start (without Docker)

1. Install MySQL 8 locally, create a database: `CREATE DATABASE libtrack;`
2. Set environment variables (or edit `application.yml` directly):
   ```bash
   export DB_HOST=localhost
   export DB_USERNAME=root
   export DB_PASSWORD=yourpassword
   export JWT_SECRET=some-random-32-plus-character-string
   ```
3. Run:
   ```bash
   ./mvnw spring-boot:run
   ```

## Authentication

```
POST /api/v1/auth/login
{
  "adminId": "VVCE-LIB-ADM-001",
  "password": "<value from your .env>"
}
```
Returns a JWT. Send it as `Authorization: Bearer <token>` on every other
request — all routes except `/api/v1/auth/**` require it.

## The bulk import endpoint (9,000+ books in one call)

```
POST /api/v1/books/bulk-import
Content-Type: multipart/form-data
Authorization: Bearer <token>

file: <your .csv or .xlsx>
```

Required columns (any order): `title, author, isbn, category, department, totalCopies`
Optional columns: `publisher, edition, rackNumber, shelfNumber, floorNumber, description, coverUrl`

**How it stays fast at scale:** rows are inserted via `JdbcTemplate.batchUpdate`
in chunks of 500 inside a single transaction — not one `INSERT` per row through
JPA. On a typical small MySQL instance, 9,000–10,000 rows imports in a few
seconds rather than minutes. Response:

```json
{
  "success": true,
  "message": "Imported 9000 of 9000 rows",
  "data": {
    "totalRows": 9000,
    "importedCount": 9000,
    "skippedCount": 0,
    "durationMs": 3120,
    "errors": []
  }
}
```

## Search (what the app's search bar calls)

```
GET /api/v1/books/search?q=algorithms&department=CSE&page=0&size=20
```

- `q` matches partial, case-insensitive text against title, author, or ISBN
- `category`, `department`, `onlyAvailable` are optional filters
- Paginated — safe against a 10,000+ row catalogue; the frontend only
  ever loads one page (default 20 rows) at a time
- Backed by indexes on `title`, `author`, `isbn`, `category`, `department`
  (see `Book.java` `@Table(indexes = ...)`), so lookups stay fast as the
  table grows. For very large catalogues (50k+), run
  `scripts/optional_fulltext_index.sql` to switch to MySQL FULLTEXT search.

## Other endpoints

| Method | Path | Purpose |
|---|---|---|
| GET/POST/PUT/DELETE | `/api/v1/books` `/api/v1/books/{id}` | Book CRUD |
| GET/POST/PUT/DELETE | `/api/v1/students` | Student CRUD + search (`?q=`) |
| GET/POST/PUT/DELETE | `/api/v1/staff` | Staff CRUD + search (`?q=`) |
| PATCH | `/api/v1/students/{id}/toggle-block` | Block/unblock a student |
| POST | `/api/v1/transactions/issue` | Issue a book |
| POST | `/api/v1/transactions/return` | Return a book (auto-calculates fine) |
| GET | `/api/v1/transactions/active` | Currently issued/overdue |
| GET | `/api/v1/dashboard/stats` | Aggregated dashboard numbers |

## Production checklist

Before this goes live for real:
- [ ] Change `JWT_SECRET`, `DB_PASSWORD`, and `DEFAULT_ADMIN_PASSWORD` in `.env`
- [ ] Change the default admin password on first login (no "change password"
      endpoint is wired up yet — add one, or update the DB row directly)
- [ ] Tighten CORS in `SecurityConfig.corsConfigurationSource()` — it's
      wide open (`*`) for development convenience
- [ ] Switch `spring.jpa.hibernate.ddl-auto` from `update` to `validate`
      and manage schema changes with Flyway or Liquibase instead
- [ ] Put the backend behind HTTPS (a reverse proxy like Nginx/Caddy, or
      your cloud provider's load balancer)
- [ ] Point `AppConstants.baseUrl` in the Flutter app at this server's
      real, public HTTPS URL

## What's New in This Update

- **Book regulation field** — replaces the old floor-number field; books can
  now be tagged with a curriculum regulation (e.g. `R2023`) and searched/
  filtered by it via `GET /api/v1/books/search?regulation=R2023`.
- **College-domain email enforcement** — `POST /api/v1/students` and
  `POST /api/v1/staff` now reject any email that isn't on the college's own
  domain (`@vvcoe.org` — see `util/CollegeEmailValidator.java`). Personal
  Gmail/Yahoo/etc. addresses are rejected with a clear error message.
- **Librarian accounts** — `Staff` now has a `role` of `STAFF` or
  `LIBRARIAN`. Create as many librarian logins as needed via
  `POST /api/v1/staff` with `"role": "LIBRARIAN"`; each gets an independent
  `staffId` + password.
- **Unified login** — `POST /api/v1/auth/login` now authenticates Admins,
  Staff, Librarians, and Students from one endpoint (it tries each table by
  ID). The response includes a `userType` field.
- **Library Settings** (`/api/v1/settings`) — opening/closing time, working
  days, borrow limits (student/staff), reservation limit, borrow duration,
  fine/day, and extension days allowed. Readable by any logged-in role,
  editable by Admin/Librarian only.
- **Feedback** (`/api/v1/feedback`) — students/staff submit feedback; Admin/
  Librarian list and resolve it.
- **Notifications** (`/api/v1/notifications`) — broadcast-only by design
  (`ALL_STUDENTS` / `ALL_STAFF` / `ALL`); there is intentionally no
  individual/per-user notification endpoint.
- **Fine payment status & manual overrides** — `PATCH
  /api/v1/transactions/{id}/fine-status` (PAID/UNPAID/WAIVED) and `PATCH
  /api/v1/transactions/{id}/manual-status` (admin corrects a transaction's
  status directly, e.g. a desk return that wasn't scanned).
- **Extension requests** — `POST /api/v1/transactions/extension/request`,
  then Admin/Librarian approve/reject via `PATCH
  /api/v1/transactions/{id}/extension/approve|reject`.
- **Downloadable reports** — `GET /api/v1/reports/transactions/download`
  streams a CSV of all transactions.
- **`/api/v1/me`** — a single endpoint that resolves to whichever account is
  logged in (Admin/Staff/Librarian/Student) for profile view, edit, and
  change-password.

### Note on schema changes
`ddl-auto: update` will auto-create the new tables/columns on next boot. The
old `floor_number` column on `books` is now unused (left in place rather than
dropped, to avoid a destructive migration) — safe to drop manually once
you've confirmed the new `regulation` column has the data you need.
