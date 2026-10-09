import 'book.dart';

class Reservation {
  final String id;
  final Book book;
  final DateTime reservationDate;
  final int queuePosition;
  final DateTime expectedAvailability;

  const Reservation({
    required this.id,
    required this.book,
    required this.reservationDate,
    required this.queuePosition,
    required this.expectedAvailability,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'].toString(),
        book: Book.fromJson(json['book'] as Map<String, dynamic>),
        reservationDate: DateTime.parse(json['reservationDate']),
        queuePosition: json['queuePosition'] ?? 1,
        expectedAvailability: DateTime.parse(json['expectedAvailability']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'book': book.toJson(),
        'reservationDate': reservationDate.toIso8601String(),
        'queuePosition': queuePosition,
        'expectedAvailability': expectedAvailability.toIso8601String(),
      };
}
