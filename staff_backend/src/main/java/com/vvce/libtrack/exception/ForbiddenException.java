package com.vvce.libtrack.exception;

/** Thrown when an authenticated staff member doesn't have permission for an action (e.g. issuing books). */
public class ForbiddenException extends RuntimeException {
    public ForbiddenException(String message) {
        super(message);
    }
}
