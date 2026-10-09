package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** A feedback message submitted by a Student or Staff member for the Admin to review. */
@Entity
@Table(name = "feedback")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Feedback {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "sender_id", length = 50)
    private String senderId;

    @Column(name = "sender_name", length = 200)
    private String senderName;

    @Column(name = "sender_type", length = 20)
    private String senderType; // STUDENT | STAFF | LIBRARIAN

    @Column(length = 2000, nullable = false)
    private String message;

    @Column(length = 20)
    @Builder.Default
    private String status = "OPEN"; // OPEN | RESOLVED

    @Column(name = "admin_response", length = 2000)
    private String adminResponse;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
