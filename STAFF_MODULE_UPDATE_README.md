# LibTrack Staff Module — Update Summary (Round 4)

## Important: update your existing seeded staff row manually
The default staff seeder only runs when the `staff` table is empty, so if
you already have a staff account in your database from a previous run,
this update **will not** overwrite it automatically. Run this once against
your MySQL database to fix the existing row:

```sql
UPDATE staff SET department = 'Computer Science & Engineering',
                  designation = 'Assistant Professor'
WHERE staff_id = 'STAFF001';
```

(Adjust `staff_id` if yours differs.) Fresh databases seeded from scratch
will get the correct values automatically.

## The big change: staff no longer borrow/issue books to students
Based on your last message, the entire "staff issues a book to a student"
model has been removed. The staff account is really a department faculty
member, not a librarian — so the app now treats them like a student:
they can only **reserve books for themselves**. Concretely:

1. **Borrow Book / Return Book removed entirely** — deleted
   `issue_book_screen.dart`, `return_book_screen.dart`,
   `transaction_service.dart`, `student_service.dart`,
   `student_info_screen.dart`, and every button/route that pointed at
   them (Dashboard, My Books, Search, Book Details, Saved Books,
   Recently Viewed, Help & Support FAQ text).
2. **Reserve / Join Queue reworked as self-service** — tapping "Reserve"
   or "Join Queue" on any book no longer asks you to search for a
   student. It reserves the book for **you**:
   - If a copy is free, it's held immediately ("Ready to Collect") and a
     confirmation screen shows the book details, matching your
     screenshot.
   - If every copy is out, you join the queue — and staff reservations
     are now given **priority over student reservations** on the backend
     (new `priority` field + queue ordering), so when a copy is returned,
     a waiting staff member is offered it before waiting students.
3. **Reservations screen → "My Reservations"** — no more Approve/Notify
   buttons for other people's requests. It now shows only your own
   active reservations (new `GET /api/reservations/mine` endpoint,
   filtered server-side to the logged-in staff member), with just
   Cancel and "Collected" (marks it picked up, which removes it from the
   list — so you'll never see already-collected reservations cluttering
   the screen).
4. **My Books tab** repurposed the same way — shows your own reserved
   books instead of a borrow/return history.
5. **Book cards** now show a single "Reserve" / "Join Queue" button
   instead of "Borrow".

## Backend changes powering the above
- `Reservation` entity: `student` is now nullable, and a new nullable
  `staff` field lets a reservation belong to a staff member instead.
  Added a `priority` column (0 = staff, 1 = student) for queue ordering.
- New endpoints: `POST /api/reservations/self` (reserve for yourself),
  `GET /api/reservations/mine` (your active reservations only),
  `POST /api/reservations/{id}/collect` (mark collected).
- Cancelling a held reservation now correctly releases the copy back to
  the shelf (`availableCopies` is incremented again).
- Schema changes apply automatically via `ddl-auto: update` on next
  startup — no manual migration needed beyond the UPDATE above.

## Other fixes from your list
- **Edit Profile dummy data fixed**: seeded department is now
  "Computer Science & Engineering" and designation "Assistant Professor"
  instead of "Central Library" / "Library Staff" (see the manual SQL
  update above if you already have a row).
- **QR code fully removed** — the only reference left in the whole
  frontend was inside `transaction_service.dart`, which is deleted.
- **Notification badge bug fixed** — `staff_shell.dart` was checking
  `n.isRead`, a field that doesn't exist on the notification model (it's
  `n.read`). This was the root cause of the badge showing a stale/wrong
  count.
- **Notifications dark-mode styling fixed** — unread notifications are
  now clearly bold and bright (`AppColors.text`, weight 800) with a
  colored left border and unread dot; read notifications are visibly
  muted (`AppColors.textMuted`, weight 600). No more washed-out grey
  look.
- **Search by department fixed** — typing a department/category keyword
  (e.g. "CSE") into the search box now matches books in that department
  too, not just title/author/ISBN. This was a backend query gap
  (`BookSpecifications.java`), not a UI issue.
- **Dashboard header** now matches the student module: big red
  "LibTrack" title with "VV College of Engineering" underneath, instead
  of "Staff Dashboard".
- **Quick Actions** now match the student module exactly: Search Books,
  My Books, Reserve Book, Notifications (previously Borrow/Return/
  Reservations tiles).

## What to double check on your end
- If your MySQL user doesn't have `ALTER TABLE` privileges, Hibernate's
  `ddl-auto: update` won't be able to add the new `staff_id`/`priority`
  columns to `reservation` automatically — grant that privilege or run
  the ALTERs manually if startup logs show a schema error.
- The Overview stat cards on the dashboard (Borrowed Today / Returned
  Today / etc.) were left as-is since they reflect library-wide activity
  from the student app, not staff-issued borrows — let me know if you'd
  rather see reservation-focused stats there instead.
