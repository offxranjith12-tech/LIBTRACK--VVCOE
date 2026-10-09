package com.vvce.libtrack.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/** Admin manually marking a fine as PAID / UNPAID / WAIVED against a student/staff transaction. */
@Data
public class FineStatusUpdateRequest {
    @NotBlank(message = "Status is required (PAID, UNPAID, or WAIVED)")
    private String status;

    /** ONLINE | OFFLINE — required when status is PAID, ignored otherwise. */
    private String paymentMethod;
}
