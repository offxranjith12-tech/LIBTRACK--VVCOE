package com.vvce.libtrack.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/** Unified "my profile" shape — works for Admin, Staff, Librarian, or Student. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MeProfileResponse {
    private String id;
    private String loginId; // adminId / staffId / registerNumber
    private String name;
    private String email;
    private String phone;
    private String role; // ADMIN | STAFF | LIBRARIAN | STUDENT
    private String department;
    private String designationOrSemester;
    private String avatarUrl;
}
