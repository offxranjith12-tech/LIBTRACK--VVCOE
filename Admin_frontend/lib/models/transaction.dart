enum TransactionStatus { issued, returned, overdue, lost }

enum BorrowerType { student, staff }

enum FinePaymentStatus { paid, unpaid, waived }

enum ExtensionStatus { none, pending, approved, rejected }

TransactionStatus _statusFromString(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'RETURNED':
      return TransactionStatus.returned;
    case 'OVERDUE':
      return TransactionStatus.overdue;
    case 'LOST':
      return TransactionStatus.lost;
    default:
      return TransactionStatus.issued;
  }
}

FinePaymentStatus _fineStatusFromString(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'PAID':
      return FinePaymentStatus.paid;
    case 'WAIVED':
      return FinePaymentStatus.waived;
    default:
      return FinePaymentStatus.unpaid;
  }
}

ExtensionStatus _extensionStatusFromString(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'PENDING':
      return ExtensionStatus.pending;
    case 'APPROVED':
      return ExtensionStatus.approved;
    case 'REJECTED':
      return ExtensionStatus.rejected;
    default:
      return ExtensionStatus.none;
  }
}

class LibraryTransaction {
  final String id;
  final String bookId;
  final String bookTitle;
  final String borrowerId;
  final String borrowerName;
  final BorrowerType borrowerType;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final double fineAmount;
  final bool fineCollected;
  final FinePaymentStatus finePaymentStatus;
  /// 'ONLINE' | 'OFFLINE' | null — how the fine was paid. Only set once finePaymentStatus is paid.
  final String? finePaymentMethod;
  final TransactionStatus status;
  final ExtensionStatus extensionStatus;
  final DateTime? requestedDueDate;

  const LibraryTransaction({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.borrowerId,
    required this.borrowerName,
    required this.borrowerType,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    this.fineAmount = 0,
    this.fineCollected = false,
    this.finePaymentStatus = FinePaymentStatus.unpaid,
    this.finePaymentMethod,
    required this.status,
    this.extensionStatus = ExtensionStatus.none,
    this.requestedDueDate,
  });

  int get overdueDays {
    final reference = returnDate ?? DateTime.now();
    if (reference.isBefore(dueDate)) return 0;
    return reference.difference(dueDate).inDays;
  }

  bool get isOverdue => status != TransactionStatus.returned && DateTime.now().isAfter(dueDate);

  LibraryTransaction copyWith({
    DateTime? returnDate,
    double? fineAmount,
    bool? fineCollected,
    FinePaymentStatus? finePaymentStatus,
    TransactionStatus? status,
    ExtensionStatus? extensionStatus,
    DateTime? requestedDueDate,
    DateTime? dueDate,
  }) {
    return LibraryTransaction(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerType: borrowerType,
      issueDate: issueDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      fineAmount: fineAmount ?? this.fineAmount,
      fineCollected: fineCollected ?? this.fineCollected,
      finePaymentStatus: finePaymentStatus ?? this.finePaymentStatus,
      status: status ?? this.status,
      extensionStatus: extensionStatus ?? this.extensionStatus,
      requestedDueDate: requestedDueDate ?? this.requestedDueDate,
    );
  }

  factory LibraryTransaction.fromJson(Map<String, dynamic> json) {
    return LibraryTransaction(
      id: json['id'].toString(),
      bookId: json['bookId'].toString(),
      bookTitle: json['bookTitle'] ?? '',
      borrowerId: json['borrowerId'] ?? '',
      borrowerName: json['borrowerName'] ?? '',
      borrowerType: (json['borrowerType'] ?? '').toString().toUpperCase() == 'STAFF' ? BorrowerType.staff : BorrowerType.student,
      issueDate: DateTime.tryParse(json['issueDate'] ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      returnDate: json['returnDate'] == null ? null : DateTime.tryParse(json['returnDate']),
      fineAmount: (json['fineAmount'] ?? 0).toDouble(),
      fineCollected: json['fineCollected'] ?? false,
      finePaymentStatus: _fineStatusFromString(json['finePaymentStatus']),
      finePaymentMethod: json['finePaymentMethod'],
      status: _statusFromString(json['status']),
      extensionStatus: _extensionStatusFromString(json['extensionStatus']),
      requestedDueDate: json['requestedDueDate'] == null ? null : DateTime.tryParse(json['requestedDueDate']),
    );
  }
}

enum ReservationStatus { pending, approved, rejected, fulfilled }

class Reservation {
  final String id;
  final String bookId;
  final String bookTitle;
  final String userId;
  final String userName;
  final BorrowerType userType;
  final DateTime reservedOn;
  final int queuePosition;
  final ReservationStatus status;

  const Reservation({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.reservedOn,
    required this.queuePosition,
    this.status = ReservationStatus.pending,
  });

  Reservation copyWith({ReservationStatus? status}) {
    return Reservation(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      userId: userId,
      userName: userName,
      userType: userType,
      reservedOn: reservedOn,
      queuePosition: queuePosition,
      status: status ?? this.status,
    );
  }
}
