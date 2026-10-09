package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Library-wide notifications only. There is intentionally no per-user /
 * individual notification target — every notification goes out to a whole
 * audience (all students, all staff, or everyone) so the admin manages one
 * simple broadcast list instead of per-person message threads.
 */
@Entity
@Table(name = "notifications")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, length = 1000)
    private String message;

    @Column(length = 30)
    @Builder.Default
    private String type = "ANNOUNCEMENT"; // DUE_REMINDER | NEW_ARRIVAL | HOLIDAY | ANNOUNCEMENT | FINE_REMINDER

    @Column(length = 20, nullable = false)
    private String audience; // ALL_STUDENTS | ALL_STAFF | ALL

    @Column(name = "sent_on")
    private LocalDateTime sentOn;

    @PrePersist
    public void prePersist() {
        if (sentOn == null) sentOn = LocalDateTime.now();
    }
}
