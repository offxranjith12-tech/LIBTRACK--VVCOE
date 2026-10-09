package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ApiResponse;
import com.vvce.libtrack.entity.LibrarySettings;
import com.vvce.libtrack.repository.LibrarySettingsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * Library timing + borrowing/reservation rules.
 * GET is open to every logged-in role (Admin, Staff, Librarian, Student) so
 * students and staff can always see the current library hours.
 * PUT is restricted to Admin/Librarian in SecurityConfig.
 */
@RestController
@RequestMapping("/api/v1/settings")
@RequiredArgsConstructor
public class SettingsController {

    private final LibrarySettingsRepository settingsRepository;

    @GetMapping
    public ApiResponse<LibrarySettings> get() {
        return ApiResponse.ok(settingsRepository.findById(1L)
                .orElseGet(() -> settingsRepository.save(LibrarySettings.builder().id(1L).build())));
    }

    @PutMapping
    public ApiResponse<LibrarySettings> update(@RequestBody LibrarySettings updated) {
        LibrarySettings settings = settingsRepository.findById(1L)
                .orElseGet(() -> LibrarySettings.builder().id(1L).build());

        settings.setOpeningTime(updated.getOpeningTime());
        settings.setClosingTime(updated.getClosingTime());
        settings.setWorkingDays(updated.getWorkingDays());
        settings.setMaxBorrowLimitStudent(updated.getMaxBorrowLimitStudent());
        settings.setMaxBorrowLimitStaff(updated.getMaxBorrowLimitStaff());
        settings.setMaxReservationLimit(updated.getMaxReservationLimit());
        settings.setBorrowDurationDays(updated.getBorrowDurationDays());
        settings.setFinePerDay(updated.getFinePerDay());
        settings.setExtensionDaysAllowed(updated.getExtensionDaysAllowed());
        settings.setAnnouncement(updated.getAnnouncement());

        return ApiResponse.ok("Settings updated", settingsRepository.save(settings));
    }
}
