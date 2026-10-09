enum NotificationType { dueReminder, reservationApproved, newArrival, fineReminder, announcement }

NotificationType notificationTypeFromString(String value) {
  return NotificationType.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => NotificationType.announcement,
  );
}

class LibNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const LibNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  LibNotification markRead() => LibNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        timestamp: timestamp,
        isRead: true,
      );

  factory LibNotification.fromJson(Map<String, dynamic> json) => LibNotification(
        id: json['id'].toString(),
        type: notificationTypeFromString(json['type'] ?? 'announcement'),
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };
}
