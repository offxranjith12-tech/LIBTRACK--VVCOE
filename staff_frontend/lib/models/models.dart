class Staff {
  final String id;
  final String name;
  final String department;
  final String designation;
  final String email;
  final String phone;
  final String address;
  final String photoUrl;

  const Staff({
    required this.id,
    required this.name,
    required this.department,
    required this.designation,
    required this.email,
    required this.phone,
    this.address = '',
    this.photoUrl = '',
  });

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
        id: json['staffId'] ?? '',
        name: json['name'] ?? '',
        department: json['department'] ?? '',
        designation: json['designation'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        photoUrl: json['photoUrl'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'staffId': id,
        'name': name,
        'department': department,
        'designation': designation,
        'email': email,
        'phone': phone,
        'address': address,
        'photoUrl': photoUrl,
      };
}

enum BookStatus { available, issued, reserved, lowStock }

BookStatus _statusFromBackend(String? s) {
  switch (s) {
    case 'AVAILABLE':
      return BookStatus.available;
    case 'LOW_STOCK':
      return BookStatus.lowStock;
    case 'ISSUED':
      return BookStatus.issued;
    default:
      return BookStatus.available;
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final String publisher;
  final String isbn;
  final String category;
  final String department;
  final String rack;
  final String shelf;
  final int totalCopies;
  final int availableCopies;
  final String description;
  final String coverUrl;
  final String regulation;
  final BookStatus? _backendStatus;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.isbn,
    required this.category,
    required this.department,
    required this.rack,
    required this.shelf,
    required this.totalCopies,
    required this.availableCopies,
    this.description = '',
    this.coverUrl = '',
    this.regulation = '',
    BookStatus? backendStatus,
  }) : _backendStatus = backendStatus;

  /// Uses the server-computed status when available (from `/api/books/...`);
  /// falls back to a local calculation for locally-constructed instances.
  BookStatus get status {
    if (_backendStatus != null) return _backendStatus;
    if (availableCopies == 0) return BookStatus.issued;
    if (availableCopies <= 1) return BookStatus.lowStock;
    return BookStatus.available;
  }

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        author: json['author'] ?? '',
        publisher: json['publisher'] ?? '',
        isbn: json['isbn'] ?? '',
        category: json['category'] ?? '',
        department: json['department'] ?? '',
        rack: json['rack'] ?? '',
        shelf: json['shelf'] ?? '',
        totalCopies: json['totalCopies'] ?? 0,
        availableCopies: json['availableCopies'] ?? 0,
        description: json['description'] ?? '',
        coverUrl: json['coverUrl'] ?? '',
        regulation: json['regulation'] ?? '',
        backendStatus: _statusFromBackend(json['status']),
      );
}

class Student {
  final String regNo;
  final String name;
  final String department;
  final int year;
  final int borrowLimit;
  final int currentBorrowed;
  final double fineDue;

  const Student({
    required this.regNo,
    required this.name,
    required this.department,
    required this.year,
    required this.borrowLimit,
    required this.currentBorrowed,
    this.fineDue = 0,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        regNo: json['regNo'] ?? '',
        name: json['name'] ?? '',
        department: json['department'] ?? '',
        year: json['year'] ?? 0,
        borrowLimit: json['borrowLimit'] ?? 0,
        currentBorrowed: json['currentBorrowed'] ?? 0,
        fineDue: (json['fineDue'] ?? 0).toDouble(),
      );
}

class BorrowTransaction {
  final String id;
  final Book book;
  final Student student;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final double fine;

  const BorrowTransaction({
    required this.id,
    required this.book,
    required this.student,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    this.fine = 0,
  });

  bool get isOverdue => returnDate == null && DateTime.now().isAfter(dueDate);
  int get daysOverdue =>
      isOverdue ? DateTime.now().difference(dueDate).inDays : 0;

  factory BorrowTransaction.fromJson(Map<String, dynamic> json) => BorrowTransaction(
        id: '${json['id']}',
        book: Book.fromJson(json['book']),
        student: Student.fromJson(json['student']),
        issueDate: DateTime.parse(json['issueDate']),
        dueDate: DateTime.parse(json['dueDate']),
        returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate']) : null,
        fine: (json['fine'] ?? 0).toDouble(),
      );
}

class Reservation {
  final String id;
  final Book book;
  final Student? student;
  final DateTime reservedOn;
  final int queuePosition;
  final bool isAvailable;
  final bool isStaffReservation;

  const Reservation({
    required this.id,
    required this.book,
    this.student,
    required this.reservedOn,
    required this.queuePosition,
    required this.isAvailable,
    this.isStaffReservation = false,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: '${json['id']}',
        book: Book.fromJson(json['book']),
        student: json['student'] != null ? Student.fromJson(json['student']) : null,
        reservedOn: DateTime.parse(json['reservedOn']),
        queuePosition: json['queuePosition'] ?? 0,
        isAvailable: json['isAvailable'] ?? false,
        isStaffReservation: json['isStaffReservation'] ?? false,
      );
}

enum NotificationType { dueDate, reservation, overdue, announcement, newArrival }

NotificationType _typeFromBackend(String? s) {
  switch (s) {
    case 'DUE_DATE':
      return NotificationType.dueDate;
    case 'RESERVATION':
      return NotificationType.reservation;
    case 'OVERDUE':
      return NotificationType.overdue;
    case 'NEW_ARRIVAL':
      return NotificationType.newArrival;
    default:
      return NotificationType.announcement;
  }
}

class LibNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  final bool read;

  const LibNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });

  factory LibNotification.fromJson(Map<String, dynamic> json) => LibNotification(
        id: '${json['id']}',
        type: _typeFromBackend(json['type']),
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        time: DateTime.parse(json['time']),
        read: json['read'] ?? false,
      );
}
