package com.vvce.libtrack.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Used by the admin's "Add Staff / Librarian" screen. Only the college's own
 * Gmail domain (e.g. ranjith@vvcoe.org) is accepted for {@code email} —
 * enforced server-side in StaffController regardless of what the client sends.
 *
 * Set {@code role} to "LIBRARIAN" to create a library-desk account (there can
 * be many librarians, each with their own staffId + password) or "STAFF" for
 * regular teaching faculty.
 */
@Data
public class CreateStaffRequest {

    @NotBlank(message = "Staff ID is required")
    private String staffId;

    @NotBlank(message = "Name is required")
    private String name;

    private String department;
    private String designation;

    @NotBlank(message = "College email is required")
    @Email(message = "Enter a valid email address")
    private String email;

    private String phone;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password;

    /** STAFF or LIBRARIAN. Defaults to STAFF if omitted. */
    private String role;

    private Integer borrowLimit;
}
