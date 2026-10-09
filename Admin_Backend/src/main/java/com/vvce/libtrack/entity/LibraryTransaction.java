package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "transactions", indexes = {
        @Index(name = "idx_txn_book", columnList = "bookId"),
        @Index(name = "idx_txn_borrower", columnList = "borrowerId"),
        @Index(name = "idx_txn_status", columnList = "status")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LibraryTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "book_id", nullable = false)
    private Long bookId;

    @Column(name = "book_title", length = 500)
    private String bookTitle;

    @Column(name = "borrower_id", nullable = false, length = 50)
    private String borrowerId;

    @Column(name = "borrower_name", length = 200)
    private String borrowerName;

    @Column(name = "borrower_type", length = 20)
    private String borrowerType; // STUDENT | STAFF

    @Column(name = "issue_date")
    private LocalDateTime issueDate;

    @Column(name = "due_date")
    private LocalDateTime dueDate;

    @Column(name = "return_date")
    private LocalDateTime returnDate;

    @Column(name = "fine_amount")
    @Builder.Default
    private Double fineAmount = 0.0;

    @Column(name = "fine_collected")
    @Builder.Default
    private Boolean fineCollected = false;

    /** PAID | UNPAID | WAIVED — set manually by the admin once cash/UPI fine is collected. */
    @Column(name = "fine_payment_status", length = 20)
    @Builder.Default
    private String finePaymentStatus = "UNPAID";

    /** ONLINE | OFFLINE — how the fine was paid. Set only when finePaymentStatus becomes PAID. */
    @Column(name = "fine_payment_method", length = 20)
    private String finePaymentMethod;

    @Column(length = 20)
    @Builder.Default
    private String status = "ISSUED"; // ISSUED | RETURNED | OVERDUE | LOST

    /** Requested new due date when the borrower asks the admin for more time. */
    @Column(name = "requested_due_date")
    private LocalDateTime requestedDueDate;

    /** NONE | PENDING | APPROVED | REJECTED */
    @Column(name = "extension_status", length = 20)
    @Builder.Default
    private String extensionStatus = "NONE";
}
