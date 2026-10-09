package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "book")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Book {

    @Id
    @Column(name = "book_id", nullable = false, unique = true)
    private String bookId;

    @Column(nullable = false)
    private String title;

    private String author;
    private String publisher;

    @Column(unique = true)
    private String isbn;

    private String category;
    private String department;
    private String rack;
    private String shelf;

    /** e.g. "R2021", "R2025" - the prescribed curriculum regulation this textbook belongs to, if any. */
    private String regulation;

    @Column(name = "total_copies")
    private Integer totalCopies;

    @Column(name = "available_copies")
    private Integer availableCopies;

    @Column(length = 2000)
    private String description;

    private String coverUrl;
}
