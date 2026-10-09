package com.vvce.libtrack.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Used by the admin's "Add Student" screen. Only the college's own Gmail
 * domain (e.g. r23cs065@vvcoe.org) is accepted for {@code email} — enforced
 * server-side in StudentController regardless of what the client sends.
 */
@Data
public class CreateStudentRequest {

    @NotBlank(message = "Register number is required")
    private String registerNumber;

    @NotBlank(message = "Name is required")
    private String name;

    private String department;
    private Integer semester;

    @NotBlank(message = "College email is required")
    @Email(message = "Enter a valid email address")
    private String email;

    private String phone;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password;

    private Integer borrowLimit;
}
