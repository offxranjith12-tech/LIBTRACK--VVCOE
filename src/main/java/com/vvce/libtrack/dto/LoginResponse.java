package com.vvce.libtrack.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {
    private String token;
    private String adminId;
    private String name;
    private String role;
    /** ADMIN | STAFF | LIBRARIAN | STUDENT */
    private String userType;
    private long expiresInMs;
}
