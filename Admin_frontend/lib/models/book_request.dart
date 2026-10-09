enum BookRequestStatus { pending, approved, rejected, issued, cancelled }

BookRequestStatus _statusFromString(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'ISSUED':
      return BookRequestStatus.issued;
    case 'APPROVED':
      return BookRequestStatus.approved;
    case 'REJECTED':
      return BookRequestStatus.rejected;
    case 'CANCELLED':
      return BookRequestStatus.cancelled;
    default:
      return BookRequestStatus.pending;
  }
}

/// A student's request to borrow a specific book, awaiting admin review.
class BookRequest {
  final String id;
  final String bookId;
  final String bookTitle;
  final String studentId;
  final String studentName;
  final String department;
  final BookRequestStatus status;
  final DateTime requestedAt;
  final DateTime? decidedAt;
  final String? transactionId;
  final String? notes;
  final String? rejectionReason;

  const BookRequest({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.studentId,
    required this.studentName,
    required this.department,
    required this.status,
    required this.requestedAt,
    this.decidedAt,
    this.transactionId,
    this.notes,
    this.rejectionReason,
  });

  factory BookRequest.fromJson(Map<String, dynamic> json) => BookRequest(
        id: json['id'].toString(),
        bookId: json['bookId'].toString(),
        bookTitle: json['bookTitle'] ?? '',
        studentId: json['studentId']?.toString() ?? '',
        studentName: json['studentName'] ?? '',
        department: json['department'] ?? '',
        status: _statusFromString(json['status']),
        requestedAt: DateTime.tryParse(json['requestedAt'] ?? '') ?? DateTime.now(),
        decidedAt: json['decidedAt'] == null ? null : DateTime.tryParse(json['decidedAt']),
        transactionId: json['transactionId']?.toString(),
        notes: json['notes'],
        rejectionReason: json['rejectionReason'],
      );
}
