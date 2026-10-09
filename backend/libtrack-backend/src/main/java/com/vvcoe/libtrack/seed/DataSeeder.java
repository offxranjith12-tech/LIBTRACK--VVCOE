package com.vvcoe.libtrack.seed;

import com.vvcoe.libtrack.model.Book;
import com.vvcoe.libtrack.model.BorrowRecord;
import com.vvcoe.libtrack.model.BorrowStatus;
import com.vvcoe.libtrack.model.Notification;
import com.vvcoe.libtrack.model.NotificationType;
import com.vvcoe.libtrack.model.Reservation;
import com.vvcoe.libtrack.model.Student;
import com.vvcoe.libtrack.repository.BookRepository;
import com.vvcoe.libtrack.repository.BorrowRecordRepository;
import com.vvcoe.libtrack.repository.NotificationRepository;
import com.vvcoe.libtrack.repository.ReservationRepository;
import com.vvcoe.libtrack.repository.StudentRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Seeds the database with a demo student and a starter book catalog
 * (including several "Regulation" textbooks) the first time the app runs
 * against an empty database. Safe to run repeatedly - it only seeds when
 * the students table is empty.
 */
@Component
public class DataSeeder implements CommandLineRunner {

    private final StudentRepository studentRepository;
    private final BookRepository bookRepository;
    private final BorrowRecordRepository borrowRecordRepository;
    private final ReservationRepository reservationRepository;
    private final NotificationRepository notificationRepository;

    public DataSeeder(StudentRepository studentRepository, BookRepository bookRepository,
                       BorrowRecordRepository borrowRecordRepository, ReservationRepository reservationRepository,
                       NotificationRepository notificationRepository) {
        this.studentRepository = studentRepository;
        this.bookRepository = bookRepository;
        this.borrowRecordRepository = borrowRecordRepository;
        this.reservationRepository = reservationRepository;
        this.notificationRepository = notificationRepository;
    }

    @Override
    public void run(String... args) {
        if (studentRepository.count() > 0) {
            return; // already seeded
        }

        Student student = new Student(
                "Vignesh R",
                "23CS086",
                "Computer Science & Engineering",
                "5th Semester",
                "r23cs086@vvcoe.org",
                "+91 98765 43210",
                "VVCOE-LIB-2023-0086",
                "password123"
        );
        studentRepository.save(student);

        List<Book> books = List.of(
                new Book("Introduction to Algorithms", "Thomas H. Cormen", "978-0262033848",
                        "Computer Science", "CSE", "MIT Press", "3rd Edition", "R-01", "S-1",
                        6, 2, "The definitive guide to algorithms - covers sorting, graph theory, and dynamic programming in depth.",
                        "B71C1C"),
                new Book("Digital Logic and Computer Design", "M. Morris Mano", "978-8120311089",
                        "Electronics", "ECE", "Pearson", "1st Edition", "R-03", "S-2",
                        5, 3, "Covers Boolean algebra, combinational and sequential circuits, and digital system design.",
                        "EF5350"),
                new Book("Higher Engineering Mathematics", "B.S. Grewal", "978-9325232655",
                        "Mathematics", "Common", "Khanna Publishers", "44th Edition", "R-02", "S-4",
                        8, 5, "A comprehensive mathematics reference covering calculus, linear algebra, and differential equations.",
                        "7F0000"),
                new Book("Software Engineering: A Practitioner's Approach", "Roger S. Pressman", "978-0078022128",
                        "Software Engineering", "CSE", "McGraw-Hill", "8th Edition", "R-04", "S-3",
                        4, 0, "Covers the full software development lifecycle, agile methods, and software quality assurance.",
                        "C62828"),
                new Book("Database System Concepts", "Abraham Silberschatz", "978-0078022159",
                        "Computer Science", "CSE", "McGraw-Hill", "7th Edition", "R-12", "S-5",
                        5, 1, "A thorough foundation on database design, relational algebra, SQL, transactions, and storage systems.",
                        "B71C1C"),
                new Book("Programming in C (R-2021 Regulation)", "Reema Thareja", "978-0199456147",
                        "Regulation", "CSE", "Oxford University Press", "3rd Edition", "R-05", "S-1",
                        12, 8, "Prescribed first-year textbook covering C programming fundamentals as per the R-2021 Anna University regulation syllabus.",
                        "C62828"),
                new Book("Data Structures and Algorithms (R-2021 Regulation)", "Ellis Horowitz", "978-8173716058",
                        "Regulation", "CSE", "Universities Press", "2nd Edition", "R-05", "S-2",
                        10, 4, "Core regulation textbook for the Data Structures and Algorithms course, aligned with the current semester curriculum.",
                        "B71C1C"),
                new Book("Basic Electrical and Electronics Engineering (R-2021 Regulation)", "S.K. Bhattacharya", "978-9332584871",
                        "Regulation", "Common", "Pearson", "2nd Edition", "R-05", "S-3",
                        8, 5, "Prescribed common first-year textbook covering fundamentals of electrical circuits and electronics for the regulation syllabus.",
                        "EF5350"),
                new Book("Engineering Physics (R-2021 Regulation)", "M.N. Avadhanulu", "978-8121908177",
                        "Regulation", "Common", "S. Chand Publishing", "10th Edition", "R-05", "S-4",
                        10, 6, "Prescribed physics textbook for first-year engineering students covering optics, quantum mechanics, and material science.",
                        "C62828"),
                new Book("Object Oriented Programming with C++ (R-2021 Regulation)", "E. Balagurusamy", "978-9339212112",
                        "Regulation", "CSE", "McGraw-Hill", "8th Edition", "R-05", "S-5",
                        9, 3, "Prescribed regulation textbook covering object-oriented concepts, classes, inheritance, and polymorphism in C++.",
                        "7F0000"),
                new Book("Environmental Science and Engineering (R-2021 Regulation)", "Benny Joseph", "978-9339219784",
                        "Regulation", "Common", "McGraw-Hill", "3rd Edition", "R-05", "S-6",
                        8, 8, "Prescribed common core textbook covering ecosystems, pollution control, and sustainability as per the regulation syllabus.",
                        "EF5350")
        );
        bookRepository.saveAll(books);

        // A couple of currently-borrowed books for the demo student
        LocalDateTime now = LocalDateTime.now();
        BorrowRecord active1 = new BorrowRecord(student, books.get(0), now.minusDays(5), now.plusDays(9));
        BorrowRecord active2 = new BorrowRecord(student, books.get(1), now.minusDays(12), now.minusDays(1));
        active2.setStatus(BorrowStatus.overdue);
        active2.setFineAmount(5.0);
        borrowRecordRepository.saveAll(List.of(active1, active2));

        // One returned record for borrow history
        BorrowRecord history = new BorrowRecord(student, books.get(2), now.minusDays(40), now.minusDays(26));
        history.setReturnDate(now.minusDays(27));
        history.setStatus(BorrowStatus.returned);
        borrowRecordRepository.save(history);

        // A reservation
        Reservation reservation = new Reservation(student, books.get(3), now.minusDays(1), 2, now.plusDays(4));
        reservationRepository.save(reservation);

        // Notifications
        notificationRepository.saveAll(List.of(
                new Notification(student, NotificationType.dueReminder, "Book Due Soon",
                        "\"Digital Logic and Computer Design\" is overdue. Please return or renew it to avoid further fines.", now.minusHours(6)),
                new Notification(student, NotificationType.reservationApproved, "Reservation Update",
                        "You are #2 in the queue for \"Software Engineering: A Practitioner's Approach\".", now.minusDays(1)),
                new Notification(student, NotificationType.newArrival, "New Arrivals",
                        "New Regulation textbooks for this semester have arrived in the library.", now.minusDays(2))
        ));
    }
}
