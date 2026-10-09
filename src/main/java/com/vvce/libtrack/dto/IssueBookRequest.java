package com.vvce.libtrack.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class IssueBookRequest {
    @NotNull
    private Long bookId;

    @NotBlank
    private String borrowerId;

    @NotBlank
    private String borrowerType;

    private Integer durationDays;
}
