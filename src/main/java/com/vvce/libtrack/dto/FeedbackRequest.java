package com.vvce.libtrack.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class FeedbackRequest {
    @NotBlank(message = "Sender ID is required")
    private String senderId;

    @NotBlank(message = "Sender name is required")
    private String senderName;

    @NotBlank(message = "Sender type is required")
    private String senderType; // STUDENT | STAFF | LIBRARIAN

    @NotBlank(message = "Message is required")
    private String message;
}
