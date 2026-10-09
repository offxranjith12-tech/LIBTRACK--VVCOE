package com.vvce.libtrack.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ReturnBookRequest {
    @NotNull
    private Long transactionId;

    private boolean fineCollected;
}
