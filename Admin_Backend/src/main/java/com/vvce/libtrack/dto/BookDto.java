package com.vvce.libtrack.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class BookDto {
    private Long id;

    @NotBlank(message = "Title is required")
    private String title;

    private String author;
    private String publisher;
    private String isbn;
    private String edition;
    private String category;
    private String department;
    private String rackNumber;
    private String shelfNumber;
    private String regulation;

    @Min(value = 1, message = "Total copies must be at least 1")
    private Integer totalCopies;

    private Integer availableCopies;
    private String description;
    private String coverUrl;
    private String qrCode;
}
