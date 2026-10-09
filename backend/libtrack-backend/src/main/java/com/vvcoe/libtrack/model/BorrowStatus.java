package com.vvcoe.libtrack.model;

/**
 * Constant names are intentionally lowercase so they serialize to JSON
 * exactly as the Flutter app's BorrowStatus enum expects
 * (issued / returned / overdue) - no custom Jackson serializer needed.
 */
public enum BorrowStatus {
    issued,
    returned,
    overdue
}
