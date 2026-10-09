package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * A student's request to borrow a specific book. Admin reviews the request,
 * verifies eligibility (borrow limit / pending fines / book availability),
 * then either rejects it or issues the book — which also marks this request
 * ISSUED and links it to the resulting {@link LibraryTransaction}.
 */
@Entity
@Table(name = "book_requests", indexes = {
        @Index(name = "idx_req_book", columnList = "bookId"),
        @Index(name = "idx_req_student", columnList = "studentId"),
        @Index(name = "idx_req_status", columnList = "status")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BookRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "book_id", nullable = false)
    private Long bookId;

    @Column(name = "book_title", length = 500)
    private String bookTitle;

    @Column(name = "student_id", nullable = false, length = 50)
    private String studentId;

    @Column(name = "student_name", length = 200)
    private String studentName;

    @Column(name = "department", length = 100)
    private String department;

    /** PENDING | APPROVED | REJECTED | ISSUED | CANCELLED */
    @Column(name = "status", length = 20, nullable = false)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "requested_at", nullable = false)
    private LocalDateTime requestedAt;

    @Column(name = "decided_at")
    private LocalDateTime decidedAt;

    /** Set once the request results in an actual issued copy. */
    @Column(name = "transaction_id")
    private Long transactionId;

    @Column(name = "notes", length = 500)
    private String notes;

    /** Reason shown to the student if rejected. */
    @Column(name = "rejection_reason", length = 500)
    private String rejectionReason;
}
