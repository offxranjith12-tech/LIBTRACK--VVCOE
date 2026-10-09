package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.StatsDtos;
import com.vvce.libtrack.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Backs the Staff Dashboard screen's 4 stat cards. */
@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/stats")
    public StatsDtos.DashboardStats getStats() {
        return dashboardService.getStats();
    }
}
