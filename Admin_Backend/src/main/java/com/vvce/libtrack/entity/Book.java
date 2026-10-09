package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "books",
    indexes = {
        @Index(name = "idx_book_title", columnList = "title"),
        @Index(name = "idx_book_author", columnList = "author"),
        @Index(name = "idx_book_isbn", columnList = "isbn"),
        @Index(name = "idx_book_category", columnList = "category"),
        @Index(name = "idx_book_department", columnList = "department"),
        @Index(name = "idx_book_regulation", columnList = "regulation")
    }
)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 500)
    private String title;

    @Column(length = 300)
    private String author;

    @Column(length = 300)
    private String publisher;

    @Column(length = 50)
    private String isbn;

    @Column(length = 50)
    private String edition;

    @Column(length = 100)
    private String category;

    @Column(length = 50)
    private String department;

    @Column(name = "rack_number", length = 20)
    private String rackNumber;

    @Column(name = "shelf_number", length = 20)
    private String shelfNumber;

    @Column(length = 50)
    private String regulation;

    @Column(name = "total_copies", nullable = false)
    @Builder.Default
    private Integer totalCopies = 1;

    @Column(name = "available_copies", nullable = false)
    @Builder.Default
    private Integer availableCopies = 1;

    @Column(length = 2000)
    private String description;

    @Column(name = "cover_url", length = 500)
    private String coverUrl;

    @Column(name = "qr_code", length = 100, unique = true)
    private String qrCode;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (availableCopies == null) availableCopies = totalCopies;
    }
}
