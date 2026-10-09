package com.vvce.libtrack.dto;

import com.vvce.libtrack.entity.BorrowTransaction;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

public record TransactionDto(
        Long id,
        BookDto book,
        StudentDto student,
        LocalDate issueDate,
        LocalDate dueDate,
        LocalDate returnDate,
        Double fine,
        Boolean fineCollected,
        String status,
        boolean overdue,
        long daysOverdue
) {
    public static TransactionDto from(BorrowTransaction t) {
        boolean overdue = t.getReturnDate() == null && t.getStatus() == BorrowTransaction.Status.ACTIVE
                && LocalDate.now().isAfter(t.getDueDate());
        long daysOverdue = overdue ? java.time.temporal.ChronoUnit.DAYS.between(t.getDueDate(), LocalDate.now()) : 0;

        return new TransactionDto(
                t.getId(), BookDto.from(t.getBook()), StudentDto.from(t.getStudent()),
                t.getIssueDate(), t.getDueDate(), t.getReturnDate(), t.getFine(), t.getFineCollected(),
                t.getStatus().name(), overdue, daysOverdue
        );
    }

    // ---- Requests ----

    public record IssueRequest(
            @NotBlank String studentRegNo,
            @NotBlank String bookId,
            LocalDate issueDate,   // optional — defaults to today
            LocalDate dueDate      // optional — defaults to today + configured loan period
    ) {}

    /** Exactly one of the three identifiers should be supplied, matching the
     *  "Search by" toggle (Student ID / Book QR / Book ISBN) on the Return
     *  Book screen. */
    public record ReturnRequest(
            String transactionId,
            String studentRegNo,
            String bookIsbn,
            String bookQrCode
    ) {}

    public record ReturnResponse(
            TransactionDto transaction,
            double fineCharged
    ) {}

    /** Powers "Extend Due Date" — lets staff push out a book's due date
     *  without returning it, instead of the student accruing a fine. */
    public record ExtendRequest(
            LocalDate newDueDate
    ) {}
}
