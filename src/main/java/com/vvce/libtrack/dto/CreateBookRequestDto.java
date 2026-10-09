package com.vvce.libtrack.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateBookRequestDto {
    @NotNull
    private Long bookId;

    @NotBlank
    private String studentId;

    private String notes;
}
