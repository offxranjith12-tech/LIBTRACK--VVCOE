import 'book.dart';

enum BorrowStatus { issued, returned, overdue }

BorrowStatus borrowStatusFromString(String value) {
  return BorrowStatus.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => BorrowStatus.issued,
  );
}

class BorrowedBook {
  final String id;
  final Book book;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final double fineAmount;
  final BorrowStatus status;

  const BorrowedBook({
    required this.id,
    required this.book,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    this.fineAmount = 0,
    required this.status,
  });

  int get remainingDays => dueDate.difference(DateTime.now()).inDays;

  bool get isDueSoon => status == BorrowStatus.issued && remainingDays <= 2 && remainingDays >= 0;

  factory BorrowedBook.fromJson(Map<String, dynamic> json) => BorrowedBook(
        id: json['id'].toString(),
        book: Book.fromJson(json['book'] as Map<String, dynamic>),
        borrowDate: DateTime.parse(json['borrowDate']),
        dueDate: DateTime.parse(json['dueDate']),
        returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate']) : null,
        fineAmount: (json['fineAmount'] ?? 0).toDouble(),
        status: borrowStatusFromString(json['status'] ?? 'issued'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'book': book.toJson(),
        'borrowDate': borrowDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
        'fineAmount': fineAmount,
        'status': status.name,
      };
}
