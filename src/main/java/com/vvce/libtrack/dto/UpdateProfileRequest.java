package com.vvce.libtrack.dto;

import lombok.Data;

/** Only name/phone/email are editable from "Edit Profile" — IDs and role are fixed. */
@Data
public class UpdateProfileRequest {
    private String name;
    private String phone;
    private String email;
}
