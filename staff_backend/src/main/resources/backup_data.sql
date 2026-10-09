-- Seed data mirrors the mock data originally used in the Flutter providers,
-- so the frontend behaves identically once pointed at this backend.
--
-- NOTE: the default staff login (anitha.r / staff123) is no longer seeded
-- here. A hand-typed BCrypt hash in this file previously did not actually
-- match "staff123", which broke login. It's now created at application
-- startup by DefaultStaffSeeder.java, which calls the real PasswordEncoder
-- bean directly — see that class if you want to change the default
-- username/password.

INSERT INTO student (reg_no, name, department, year, borrow_limit, current_borrowed, fine_due)
SELECT '21CSE045', 'Karthik S.', 'CSE', 3, 4, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM student WHERE reg_no = '21CSE045');

INSERT INTO student (reg_no, name, department, year, borrow_limit, current_borrowed, fine_due)
SELECT '22ECE019', 'Divya M.', 'ECE', 2, 3, 3, 30
WHERE NOT EXISTS (SELECT 1 FROM student WHERE reg_no = '22ECE019');

INSERT INTO book (book_id, title, author, publisher, isbn, category, department, rack, shelf, total_copies, available_copies, description)
SELECT 'B001', 'Data Structures & Algorithms in Java', 'Robert Lafore', 'Pearson', '978-0672324536', 'Computer Science', 'CSE', 'R-12', 'S-3', 6, 2, 'A comprehensive introduction to data structures and algorithms using Java, with practical examples and visualizations.'
WHERE NOT EXISTS (SELECT 1 FROM book WHERE book_id = 'B001');

INSERT INTO book (book_id, title, author, publisher, isbn, category, department, rack, shelf, total_copies, available_copies, description)
SELECT 'B002', 'Operating System Concepts', 'Silberschatz, Galvin', 'Wiley', '978-1119800361', 'Computer Science', 'CSE', 'R-14', 'S-1', 4, 0, 'The classic textbook covering process management, memory, and file systems.'
WHERE NOT EXISTS (SELECT 1 FROM book WHERE book_id = 'B002');

INSERT INTO book (book_id, title, author, publisher, isbn, category, department, rack, shelf, total_copies, available_copies, description)
SELECT 'B003', 'Digital Signal Processing', 'John G. Proakis', 'Prentice Hall', '978-0131873742', 'Electronics', 'ECE', 'R-21', 'S-2', 5, 5, 'Principles, algorithms, and applications of digital signal processing.'
WHERE NOT EXISTS (SELECT 1 FROM book WHERE book_id = 'B003');

INSERT INTO book (book_id, title, author, publisher, isbn, category, department, rack, shelf, total_copies, available_copies, description)
SELECT 'B004', 'Engineering Thermodynamics', 'P.K. Nag', 'McGraw Hill', '978-9339221408', 'Mechanical', 'MECH', 'R-30', 'S-4', 3, 1, 'Fundamental concepts of thermodynamics applied to engineering systems.'
WHERE NOT EXISTS (SELECT 1 FROM book WHERE book_id = 'B004');

INSERT INTO book (book_id, title, author, publisher, isbn, category, department, rack, shelf, regulation, total_copies, available_copies, description)
SELECT 'B005', 'Programming in C (R-2021 Regulation)', 'Reema Thareja', 'Oxford University Press', '978-0199456147', 'Regulation', 'CSE', 'R-05', 'S-1', 'R2021', 12, 8, 'Prescribed first-year textbook covering C programming fundamentals as per the R-2021 curriculum regulation.'
WHERE NOT EXISTS (SELECT 1 FROM book WHERE book_id = 'B005');

INSERT INTO book (book_id, title, author, publisher, isbn, category, department, rack, shelf, regulation, total_copies, available_copies, description)
SELECT 'B006', 'Data Structures and Algorithms (R-2021 Regulation)', 'Ellis Horowitz', 'Universities Press', '978-8173716058', 'Regulation', 'CSE', 'R-05', 'S-2', 'R2021', 10, 4, 'Core regulation textbook for the Data Structures and Algorithms course, R-2021 curriculum.'
WHERE NOT EXISTS (SELECT 1 FROM book WHERE book_id = 'B006');

INSERT INTO book (book_id, title, author, publisher, isbn, category, department, rack, shelf, regulation, total_copies, available_copies, description)
SELECT 'B007', 'Engineering Physics (R-2025 Regulation)', 'M.N. Avadhanulu', 'S. Chand Publishing', '978-8121908177', 'Regulation', 'Common', 'R-05', 'S-4', 'R2025', 10, 6, 'Prescribed physics textbook for first-year engineering students under the updated R-2025 curriculum.'
WHERE NOT EXISTS (SELECT 1 FROM book WHERE book_id = 'B007');

INSERT INTO book (book_id, title, author, publisher, isbn, category, department, rack, shelf, regulation, total_copies, available_copies, description)
SELECT 'B008', 'Object Oriented Programming with C++ (R-2025 Regulation)', 'E. Balagurusamy', 'McGraw-Hill', '978-9339212112', 'Regulation', 'CSE', 'R-05', 'S-5', 'R2025', 9, 0, 'Prescribed regulation textbook covering object-oriented concepts under the R-2025 curriculum.'
WHERE NOT EXISTS (SELECT 1 FROM book WHERE book_id = 'B008');

INSERT INTO book (book_id, title, author, publisher, isbn, category, department, rack, shelf, regulation, total_copies, available_copies, description)
SELECT 'B009', 'Database Management Systems (R-2023 Regulation)', 'Raghu Ramakrishnan', 'McGraw-Hill', '978-0072465631', 'Regulation', 'CSE', 'R-05', 'S-6', 'R2023', 10, 5, 'Prescribed textbook for the Database Management Systems course under the R-2023 curriculum regulation.'
WHERE NOT EXISTS (SELECT 1 FROM book WHERE book_id = 'B009');

INSERT INTO book (book_id, title, author, publisher, isbn, category, department, rack, shelf, regulation, total_copies, available_copies, description)
SELECT 'B010', 'Discrete Mathematics (R-2023 Regulation)', 'Kenneth Rosen', 'McGraw-Hill', '978-0073383095', 'Regulation', 'Common', 'R-05', 'S-7', 'R2023', 8, 3, 'Prescribed mathematics textbook covering logic, set theory, and combinatorics under the R-2023 curriculum.'
WHERE NOT EXISTS (SELECT 1 FROM book WHERE book_id = 'B010');

-- Sample active borrows so the Dashboard stats / My Books tab aren't all zero on first run
INSERT INTO borrow_transaction (book_id, reg_no, issue_date, due_date, fine, fine_collected, status)
SELECT 'B002', '22ECE019', CURDATE() - INTERVAL 20 DAY, CURDATE() - INTERVAL 6 DAY, 0, false, 'ACTIVE'
WHERE NOT EXISTS (
  SELECT 1 FROM borrow_transaction WHERE book_id = 'B002' AND reg_no = '22ECE019' AND status = 'ACTIVE'
);

INSERT INTO borrow_transaction (book_id, reg_no, issue_date, due_date, fine, fine_collected, status)
SELECT 'B001', '21CSE045', CURDATE() - INTERVAL 5 DAY, CURDATE() + INTERVAL 9 DAY, 0, false, 'ACTIVE'
WHERE NOT EXISTS (
  SELECT 1 FROM borrow_transaction WHERE book_id = 'B001' AND reg_no = '21CSE045' AND status = 'ACTIVE'
);

-- Sample reservation so the Reservations screen isn't empty on first run
INSERT INTO reservation (book_id, reg_no, reserved_on, queue_position, status)
SELECT 'B004', '22ECE019', NOW() - INTERVAL 5 HOUR, 1, 'AVAILABLE'
WHERE NOT EXISTS (
  SELECT 1 FROM reservation WHERE book_id = 'B004' AND reg_no = '22ECE019'
);

-- Sample notifications so the Alerts view isn't empty on first run
INSERT INTO notification (type, title, message, time, is_read, staff_id)
SELECT 'OVERDUE', 'Overdue Book Alert', 'Operating System Concepts is 6 days overdue for Divya M. (22ECE019).', NOW() - INTERVAL 1 HOUR, false, NULL
WHERE NOT EXISTS (SELECT 1 FROM notification WHERE title = 'Overdue Book Alert');

INSERT INTO notification (type, title, message, time, is_read, staff_id)
SELECT 'RESERVATION', 'New Reservation Request', 'Engineering Thermodynamics reserved by Divya M. - now available.', NOW() - INTERVAL 3 HOUR, false, NULL
WHERE NOT EXISTS (SELECT 1 FROM notification WHERE title = 'New Reservation Request');

INSERT INTO notification (type, title, message, time, is_read, staff_id)
SELECT 'DUE_DATE', 'Due Date Reminder', '5 books are due within the next 2 days.', NOW() - INTERVAL 8 HOUR, true, NULL
WHERE NOT EXISTS (SELECT 1 FROM notification WHERE title = 'Due Date Reminder');

INSERT INTO notification (type, title, message, time, is_read, staff_id)
SELECT 'NEW_ARRIVAL', 'New Book Arrivals', '12 new titles added to the Computer Science section.', NOW() - INTERVAL 1 DAY, true, NULL
WHERE NOT EXISTS (SELECT 1 FROM notification WHERE title = 'New Book Arrivals');
