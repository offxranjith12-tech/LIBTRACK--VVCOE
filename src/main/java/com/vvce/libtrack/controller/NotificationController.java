package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ApiResponse;
import com.vvce.libtrack.dto.SendNotificationRequest;
import com.vvce.libtrack.entity.Notification;
import com.vvce.libtrack.exception.BadRequestException;
import com.vvce.libtrack.repository.NotificationRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;

/**
 * Broadcast-only notifications — sending POST is restricted to Admin/Librarian
 * in SecurityConfig. Every account that's part of the chosen audience sees the
 * same message; there is no individual/per-user notification here by design.
 */
@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private static final Set<String> VALID_AUDIENCES = Set.of("ALL_STUDENTS", "ALL_STAFF", "ALL");

    private final NotificationRepository notificationRepository;

    @GetMapping
    public ApiResponse<List<Notification>> getAll() {
        return ApiResponse.ok(notificationRepository.findAllByOrderBySentOnDesc());
    }

    @PostMapping
    public ApiResponse<Notification> send(@Valid @RequestBody SendNotificationRequest request) {
        String audience = request.getAudience().toUpperCase();
        if (!VALID_AUDIENCES.contains(audience)) {
            throw new BadRequestException("Audience must be one of " + VALID_AUDIENCES + " (individual notifications are not supported)");
        }

        Notification notification = Notification.builder()
                .title(request.getTitle())
                .message(request.getMessage())
                .type(request.getType() == null || request.getType().isBlank() ? "ANNOUNCEMENT" : request.getType().toUpperCase())
                .audience(audience)
                .build();

        return ApiResponse.ok("Notification sent", notificationRepository.save(notification));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        notificationRepository.deleteById(id);
        return ApiResponse.ok("Notification deleted", null);
    }
}
