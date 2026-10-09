package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "reservation")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Reservation {

    public enum Status { WAITING, AVAILABLE, APPROVED, CANCELLED, FULFILLED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "reg_no", nullable = true)
    private Student student;

    /** Set instead of {@link #student} when a staff member reserves a book for themselves. */
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "staff_id", nullable = true)
    private Staff staff;

    @Column(name = "reserved_on", nullable = false)
    private LocalDateTime reservedOn;

    @Column(name = "queue_position")
    private Integer queuePosition;

    /** 0 = staff (served first), 1 = student. Used to order the queue so staff get priority. */
    @Column(name = "priority")
    @Builder.Default
    private Integer priority = 1;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private Status status = Status.WAITING;

    public boolean isStaffReservation() {
        return staff != null;
    }
}
