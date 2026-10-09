package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "book_recommendation")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BookRecommendation {

    public enum Status { PENDING, APPROVED, DECLINED, ACQUIRED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "staff_id")
    private String staffId;

    @Column(nullable = false)
    private String title;

    private String author;

    @Column(length = 1000)
    private String reason;

    @Column(name = "requested_at")
    private LocalDateTime requestedAt;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private Status status = Status.PENDING;
}
