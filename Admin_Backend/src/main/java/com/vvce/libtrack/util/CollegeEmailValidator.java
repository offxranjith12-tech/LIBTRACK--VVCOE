package com.vvce.libtrack.util;

import com.vvce.libtrack.exception.BadRequestException;

/**
 * Enforces that every Student / Staff / Librarian account is created with the
 * college's own Gmail domain (e.g. r23cs065@vvcoe.org, ranjith@vvcoe.org).
 * Personal Gmail addresses (gmail.com, yahoo.com, etc.) are strictly rejected —
 * only accounts under the configured college domain may access LibTrack.
 */
public final class CollegeEmailValidator {

    private CollegeEmailValidator() {
    }

    /** Change this if the college ever migrates to a different mail domain. */
    public static final String ALLOWED_DOMAIN = "vvcoe.org";

    public static void validate(String email) {
        if (email == null || email.isBlank()) {
            throw new BadRequestException("College email is required");
        }
        String normalized = email.trim().toLowerCase();
        String[] parts = normalized.split("@");
        if (parts.length != 2 || !parts[1].equals(ALLOWED_DOMAIN)) {
            throw new BadRequestException(
                    "Only official college email addresses (@" + ALLOWED_DOMAIN + ") are allowed. " +
                    "Personal Gmail or other personal email addresses cannot be used to access LibTrack."
            );
        }
    }
}
