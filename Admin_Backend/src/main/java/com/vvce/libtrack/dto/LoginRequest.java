package com.vvce.libtrack.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {
    /**
     * Generic login identifier — an Admin ID, a Staff/Librarian staffId, or a
     * Student registerNumber. Field name kept as "adminId" for backward
     * compatibility with existing clients; it works for every role.
     */
    @NotBlank
    private String adminId;

    @NotBlank
    private String password;
}
