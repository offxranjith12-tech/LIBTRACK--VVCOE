package com.vvce.libtrack.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/** Admin manually overriding a transaction's status (e.g. correcting a return that wasn't scanned). */
@Data
public class ManualStatusUpdateRequest {
    @NotBlank(message = "Status is required (ISSUED, RETURNED, OVERDUE, or LOST)")
    private String status;
}
