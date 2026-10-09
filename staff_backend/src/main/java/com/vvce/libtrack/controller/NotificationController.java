package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.NotificationDto;
import com.vvce.libtrack.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Backs the Notifications screen. */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public List<NotificationDto> getAll(Authentication auth) {
        // Token subject is the username; staffId is embedded as a JWT claim on
        // the frontend's stored profile, so we resolve it via the staff lookup
        // in NotificationService if you prefer — kept simple here by passing
        // the username through and matching staffId server-side if needed.
        return notificationService.getAll(auth.getName());
    }

    /** Mark a single notification as read (tap on a notification card). */
    @PostMapping("/{id}/read")
    public void markRead(@PathVariable Long id) {
        notificationService.markRead(id);
    }

    /** "Mark all read" action. */
    @PostMapping("/read-all")
    public void markAllRead(Authentication auth) {
        notificationService.markAllRead(auth.getName());
    }
}
