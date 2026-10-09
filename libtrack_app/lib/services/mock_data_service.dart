import '../models/book.dart';
import '../models/borrowed_book.dart';
import '../models/notification_model.dart';
import '../models/reservation.dart';
import '../models/student.dart';

/// Provides realistic sample data so the app is fully demo-able before the
/// Spring Boot + MySQL backend is wired in. Replace calls to this class with
/// ApiService calls once your endpoints are ready — method signatures below
/// intentionally mirror what the real repository layer will look like.
class MockDataService {
  static final Student currentStudent = Student(
    id: '1',
    name: 'Vignesh R',
    registerNumber: '23CS086',
    department: 'Computer Science & Engineering',
    semester: '5th Semester',
    email: 'r23cs086@vvcoe.org',
    phone: '+91 98765 43210',
    libraryCardNumber: 'VVCOE-LIB-2023-0086',
  );

  static final List<Book> _books = [
    const Book(
      id: 'b1',
      title: 'Introduction to Algorithms',
      author: 'Thomas H. Cormen',
      isbn: '978-0262046305',
      category: 'Computer Science',
      department: 'CSE',
      publisher: 'MIT Press',
      edition: '4th Edition',
      rackNumber: 'R-12',
      shelfNumber: 'S-4',
      totalCopies: 6,
      availableCopies: 3,
      description:
          'A comprehensive textbook covering a broad range of algorithms in depth, with rigorous mathematical analysis and pseudocode.',
      coverColorHex: 'B71C1C',
    ),
    const Book(
      id: 'b2',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '978-0132350884',
      category: 'Software Engineering',
      department: 'CSE',
      publisher: 'Prentice Hall',
      edition: '1st Edition',
      rackNumber: 'R-09',
      shelfNumber: 'S-2',
      totalCopies: 4,
      availableCopies: 0,
      description:
          'A handbook of agile software craftsmanship that teaches principles, patterns and practices of writing clean code.',
      coverColorHex: '7F0000',
    ),
    const Book(
      id: 'b3',
      title: 'Digital Electronics',
      author: 'Morris Mano',
      isbn: '978-0132543269',
      category: 'Electronics',
      department: 'ECE',
      publisher: 'Pearson',
      edition: '5th Edition',
      rackNumber: 'R-21',
      shelfNumber: 'S-1',
      totalCopies: 5,
      availableCopies: 2,
      description:
          'Covers digital logic design, Boolean algebra, combinational and sequential circuits with practical examples.',
      coverColorHex: 'EF5350',
    ),
    const Book(
      id: 'b4',
      title: 'Engineering Mathematics',
      author: 'B.S. Grewal',
      isbn: '978-8174091956',
      category: 'Mathematics',
      department: 'Common',
      publisher: 'Khanna Publishers',
      edition: '44th Edition',
      rackNumber: 'R-03',
      shelfNumber: 'S-6',
      totalCopies: 10,
      availableCopies: 6,
      description:
          'A complete reference for engineering mathematics covering calculus, linear algebra, and differential equations.',
      coverColorHex: 'C62828',
    ),
    const Book(
      id: 'b5',
      title: 'Database System Concepts',
      author: 'Abraham Silberschatz',
      isbn: '978-0078022159',
      category: 'Computer Science',
      department: 'CSE',
      publisher: 'McGraw-Hill',
      edition: '7th Edition',
      rackNumber: 'R-12',
      shelfNumber: 'S-5',
      totalCopies: 5,
      availableCopies: 1,
      description:
          'A thorough foundation on database design, relational algebra, SQL, transactions, and storage systems.',
      coverColorHex: 'B71C1C',
    ),
    const Book(
      id: 'b6',
      title: 'Programming in C (R-2021 Regulation)',
      author: 'Reema Thareja',
      isbn: '978-0199456147',
      category: 'Regulation',
      department: 'CSE',
      publisher: 'Oxford University Press',
      edition: '3rd Edition',
      rackNumber: 'R-05',
      shelfNumber: 'S-1',
      totalCopies: 12,
      availableCopies: 8,
      description:
          'Prescribed first-year textbook covering C programming fundamentals as per the R-2021 Anna University regulation syllabus.',
      coverColorHex: 'C62828',
    ),
    const Book(
      id: 'b7',
      title: 'Data Structures and Algorithms (R-2021 Regulation)',
      author: 'Ellis Horowitz',
      isbn: '978-8173716058',
      category: 'Regulation',
      department: 'CSE',
      publisher: 'Universities Press',
      edition: '2nd Edition',
      rackNumber: 'R-05',
      shelfNumber: 'S-2',
      totalCopies: 10,
      availableCopies: 4,
      description:
          'Core regulation textbook for the Data Structures and Algorithms course, aligned with the current semester curriculum.',
      coverColorHex: 'B71C1C',
    ),
    const Book(
      id: 'b8',
      title: 'Basic Electrical and Electronics Engineering (R-2021 Regulation)',
      author: 'S.K. Bhattacharya',
      isbn: '978-9332584871',
      category: 'Regulation',
      department: 'Common',
      publisher: 'Pearson',
      edition: '2nd Edition',
      rackNumber: 'R-05',
      shelfNumber: 'S-3',
      totalCopies: 8,
      availableCopies: 5,
      description:
          'Prescribed common first-year textbook covering fundamentals of electrical circuits and electronics for the regulation syllabus.',
      coverColorHex: 'EF5350',
    ),
    const Book(
      id: 'b9',
      title: 'Engineering Physics (R-2021 Regulation)',
      author: 'M.N. Avadhanulu',
      isbn: '978-8121908177',
      category: 'Regulation',
      department: 'Common',
      publisher: 'S. Chand Publishing',
      edition: '10th Edition',
      rackNumber: 'R-05',
      shelfNumber: 'S-4',
      totalCopies: 10,
      availableCopies: 6,
      description:
          'Prescribed physics textbook for first-year engineering students covering optics, quantum mechanics, and material science.',
      coverColorHex: 'C62828',
    ),
    const Book(
      id: 'b10',
      title: 'Object Oriented Programming with C++ (R-2021 Regulation)',
      author: 'E. Balagurusamy',
      isbn: '978-9339212112',
      category: 'Regulation',
      department: 'CSE',
      publisher: 'McGraw-Hill',
      edition: '8th Edition',
      rackNumber: 'R-05',
      shelfNumber: 'S-5',
      totalCopies: 9,
      availableCopies: 3,
      description:
          'Prescribed regulation textbook covering object-oriented concepts, classes, inheritance, and polymorphism in C++.',
      coverColorHex: '7F0000',
    ),
    const Book(
      id: 'b11',
      title: 'Environmental Science and Engineering (R-2021 Regulation)',
      author: 'Benny Joseph',
      isbn: '978-9339219784',
      category: 'Regulation',
      department: 'Common',
      publisher: 'McGraw-Hill',
      edition: '3rd Edition',
      rackNumber: 'R-05',
      shelfNumber: 'S-6',
      totalCopies: 8,
      availableCopies: 8,
      description:
          'Prescribed common core textbook covering ecosystems, pollution control, and sustainability as per the regulation syllabus.',
      coverColorHex: 'EF5350',
    ),
  ];

  static List<Book> get books => _books;

  static List<Book> search({
    String query = '',
    String? category,
    String? department,
    String? author,
    String? rack,
    BookAvailability? availability,
  }) {
    return filterBooks(
      _books,
      query: query,
      category: category,
      department: department,
      author: author,
      rack: rack,
      availability: availability,
    );
  }

  /// Same matching logic as [search], but operates on any list of books -
  /// used so the Search screen can filter whatever the current catalog is
  /// (mock data, or the real list fetched from the backend) identically.
  static List<Book> filterBooks(
    List<Book> source, {
    String query = '',
    String? category,
    String? department,
    String? author,
    String? rack,
    BookAvailability? availability,
  }) {
    return source.where((b) {
      final matchesQuery = query.isEmpty ||
          b.title.toLowerCase().contains(query.toLowerCase()) ||
          b.author.toLowerCase().contains(query.toLowerCase()) ||
          b.isbn.contains(query);
      final matchesCategory = category == null || category == 'All' || b.category == category;
      final matchesDept = department == null || department == 'All' || b.department == department;
      final matchesAuthor = author == null || author == 'All' || b.author == author;
      final matchesRack = rack == null || rack == 'All' || b.rackNumber == rack;
      final matchesAvailability = availability == null || b.availability == availability;
      return matchesQuery &&
          matchesCategory &&
          matchesDept &&
          matchesAuthor &&
          matchesRack &&
          matchesAvailability;
    }).toList();
  }

  static List<BorrowedBook> get borrowedBooks {
    final now = DateTime.now();
    return [
      BorrowedBook(
        id: 'bb1',
        book: _books[0],
        borrowDate: now.subtract(const Duration(days: 12)),
        dueDate: now.add(const Duration(days: 2)),
        status: BorrowStatus.issued,
      ),
      BorrowedBook(
        id: 'bb2',
        book: _books[3],
        borrowDate: now.subtract(const Duration(days: 20)),
        dueDate: now.subtract(const Duration(days: 3)),
        status: BorrowStatus.overdue,
        fineAmount: 30,
      ),
      BorrowedBook(
        id: 'bb3',
        book: _books[2],
        borrowDate: now.subtract(const Duration(days: 40)),
        dueDate: now.subtract(const Duration(days: 26)),
        returnDate: now.subtract(const Duration(days: 27)),
        status: BorrowStatus.returned,
      ),
    ];
  }

  static List<Reservation> get reservations {
    final now = DateTime.now();
    return [
      Reservation(
        id: 'r1',
        book: _books[1],
        reservationDate: now.subtract(const Duration(days: 3)),
        queuePosition: 2,
        expectedAvailability: now.add(const Duration(days: 4)),
      ),
      Reservation(
        id: 'r2',
        book: _books[4],
        reservationDate: now.subtract(const Duration(days: 1)),
        queuePosition: 1,
        expectedAvailability: now.add(const Duration(days: 1)),
      ),
    ];
  }

  static List<LibNotification> get notifications {
    final now = DateTime.now();
    return [
      LibNotification(
        id: 'n1',
        type: NotificationType.dueReminder,
        title: 'Book Due Soon',
        message: '"Introduction to Algorithms" is due in 2 days. Renew now to avoid fines.',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      LibNotification(
        id: 'n2',
        type: NotificationType.reservationApproved,
        title: 'Reservation Approved',
        message: '"Database System Concepts" is now available for pickup at the front desk.',
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      LibNotification(
        id: 'n3',
        type: NotificationType.newArrival,
        title: 'New Arrivals in CSE',
        message: '12 new titles have been added to the Computer Science section this week.',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      LibNotification(
        id: 'n4',
        type: NotificationType.fineReminder,
        title: 'Pending Fine',
        message: 'You have a pending fine of ₹30 for an overdue book. Please clear it soon.',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      LibNotification(
        id: 'n5',
        type: NotificationType.announcement,
        title: 'Library Timing Update',
        message: 'The library will remain open until 8 PM during exam week.',
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  static double get pendingFine =>
      borrowedBooks.fold(0.0, (sum, b) => sum + b.fineAmount);
}
