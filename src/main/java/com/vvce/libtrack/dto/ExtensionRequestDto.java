package com.vvce.libtrack.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

/** A borrower asking the admin for more time to return a book. */
@Data
public class ExtensionRequestDto {
    @NotNull
    private Long transactionId;

    /** How many extra days the borrower is requesting. */
    private Integer extraDays;
}
