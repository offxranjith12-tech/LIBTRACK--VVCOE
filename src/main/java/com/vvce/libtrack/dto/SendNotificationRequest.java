package com.vvce.libtrack.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SendNotificationRequest {
    @NotBlank(message = "Title is required")
    private String title;

    @NotBlank(message = "Message is required")
    private String message;

    private String type;

    /** ALL_STUDENTS | ALL_STAFF | ALL — individual/per-user targeting is not supported. */
    @NotBlank(message = "Audience is required")
    private String audience;
}
