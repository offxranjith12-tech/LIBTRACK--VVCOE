package com.vvcoe.libtrack.controller;

import com.vvcoe.libtrack.model.Notification;
import com.vvcoe.libtrack.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping("/students/{studentId}/notifications")
    public ResponseEntity<List<Notification>> getForStudent(@PathVariable Long studentId) {
        return ResponseEntity.ok(notificationService.getForStudent(studentId));
    }

    @PutMapping("/notifications/{id}/read")
    public ResponseEntity<Notification> markRead(@PathVariable Long id) {
        return ResponseEntity.ok(notificationService.markRead(id));
    }
}
