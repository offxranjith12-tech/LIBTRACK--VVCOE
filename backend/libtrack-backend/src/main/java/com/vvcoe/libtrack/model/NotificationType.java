package com.vvcoe.libtrack.model;

/**
 * Constant names intentionally match the Flutter app's NotificationType
 * enum exactly (including camelCase) so JSON serializes without a custom
 * Jackson converter.
 */
public enum NotificationType {
    dueReminder,
    reservationApproved,
    newArrival,
    fineReminder,
    announcement
}
