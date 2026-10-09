package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "feedback")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Feedback {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "staff_id")
    private String staffId;

    @Column(length = 2000, nullable = false)
    private String message;

    /** 1-5 star rating. */
    private Integer rating;

    @Column(name = "submitted_at")
    private LocalDateTime submittedAt;
}
