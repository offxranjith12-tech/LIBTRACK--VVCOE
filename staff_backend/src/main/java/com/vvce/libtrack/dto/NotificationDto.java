package com.vvce.libtrack.dto;

import com.vvce.libtrack.entity.LibNotification;

import java.time.LocalDateTime;

public record NotificationDto(
        Long id,
        String type,
        String title,
        String message,
        LocalDateTime time,
        boolean read
) {
    public static NotificationDto from(LibNotification n) {
        return new NotificationDto(n.getId(), n.getType().name(), n.getTitle(), n.getMessage(),
                n.getTime(), Boolean.TRUE.equals(n.getIsRead()));
    }
}
