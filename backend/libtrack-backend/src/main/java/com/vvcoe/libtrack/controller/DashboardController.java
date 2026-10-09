package com.vvcoe.libtrack.controller;

import com.vvcoe.libtrack.service.DashboardService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/students/{studentId}/dashboard-stats")
    public ResponseEntity<Map<String, Object>> getStats(@PathVariable Long studentId) {
        return ResponseEntity.ok(dashboardService.getStats(studentId));
    }
}
