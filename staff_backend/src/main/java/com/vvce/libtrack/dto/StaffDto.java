package com.vvce.libtrack.dto;

import com.vvce.libtrack.entity.Staff;

public record StaffDto(
        String staffId,
        String name,
        String department,
        String designation,
        String email,
        String phone,
        String address,
        String photoUrl
) {
    public static StaffDto from(Staff s) {
        return new StaffDto(s.getStaffId(), s.getName(), s.getDepartment(), s.getDesignation(),
                s.getEmail(), s.getPhone(), s.getAddress(), s.getPhotoUrl());
    }
}
