package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.StaffDto;
import com.vvce.libtrack.service.StaffService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/** Backs the Profile screen. */
@RestController
@RequestMapping("/api/staff")
@RequiredArgsConstructor
public class StaffController {

    private final StaffService staffService;

    @GetMapping("/me")
    public StaffDto getProfile(Authentication auth) {
        return staffService.getProfile(auth.getName());
    }

    /** Powers "Edit Profile" on the Profile screen. */
    @PutMapping("/me")
    public StaffDto updateProfile(Authentication auth, @RequestBody StaffDto update) {
        return staffService.updateProfile(auth.getName(), update);
    }
}
