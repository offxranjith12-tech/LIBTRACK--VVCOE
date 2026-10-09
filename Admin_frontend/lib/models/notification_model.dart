enum NotificationType { dueReminder, newArrival, holiday, announcement, fineReminder }

/// Only whole-audience broadcasts are supported — there is intentionally no
/// "individual" / per-user notification target, matching the backend.
enum NotificationAudience { allStudents, allStaff, all }

String audienceApiValue(NotificationAudience a) {
  switch (a) {
    case NotificationAudience.allStudents:
      return 'ALL_STUDENTS';
    case NotificationAudience.allStaff:
      return 'ALL_STAFF';
    case NotificationAudience.all:
      return 'ALL';
  }
}

String typeApiValue(NotificationType t) {
  switch (t) {
    case NotificationType.dueReminder:
      return 'DUE_REMINDER';
    case NotificationType.newArrival:
      return 'NEW_ARRIVAL';
    case NotificationType.holiday:
      return 'HOLIDAY';
    case NotificationType.announcement:
      return 'ANNOUNCEMENT';
    case NotificationType.fineReminder:
      return 'FINE_REMINDER';
  }
}

NotificationType typeFromApiValue(String value) {
  switch (value.toUpperCase()) {
    case 'DUE_REMINDER':
      return NotificationType.dueReminder;
    case 'NEW_ARRIVAL':
      return NotificationType.newArrival;
    case 'HOLIDAY':
      return NotificationType.holiday;
    case 'FINE_REMINDER':
      return NotificationType.fineReminder;
    default:
      return NotificationType.announcement;
  }
}

class LibNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationAudience audience;
  final DateTime sentOn;

  const LibNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.audience,
    required this.sentOn,
  });

  String get typeLabel {
    switch (type) {
      case NotificationType.dueReminder:
        return 'Due Reminder';
      case NotificationType.newArrival:
        return 'New Arrival';
      case NotificationType.holiday:
        return 'Holiday Notice';
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.fineReminder:
        return 'Fine Reminder';
    }
  }

  String get audienceLabel {
    switch (audience) {
      case NotificationAudience.allStudents:
        return 'All Students';
      case NotificationAudience.allStaff:
        return 'All Staff';
      case NotificationAudience.all:
        return 'Everyone';
    }
  }
}
