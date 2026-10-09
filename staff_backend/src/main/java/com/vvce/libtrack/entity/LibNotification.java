package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "notification")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LibNotification {

    public enum Type { DUE_DATE, RESERVATION, OVERDUE, ANNOUNCEMENT, NEW_ARRIVAL }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    private Type type;

    private String title;

    @Column(length = 1000)
    private String message;

    private LocalDateTime time;

    @Builder.Default
    private Boolean isRead = false;

    /** Which staff member this alert targets; null = broadcast to all staff. */
    private String staffId;
}
