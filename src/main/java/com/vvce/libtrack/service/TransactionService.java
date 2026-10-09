package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.IssueBookRequest;
import com.vvce.libtrack.dto.ReturnBookRequest;
import com.vvce.libtrack.entity.Book;
import com.vvce.libtrack.entity.LibraryTransaction;
import com.vvce.libtrack.entity.Staff;
import com.vvce.libtrack.entity.Student;
import com.vvce.libtrack.exception.BadRequestException;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.StaffRepository;
import com.vvce.libtrack.repository.StudentRepository;
import com.vvce.libtrack.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final BookService bookService;
    private final StudentRepository studentRepository;
    private final StaffRepository staffRepository;

    private static final double FINE_PER_DAY = 2.0;
    private static final int DEFAULT_DURATION_DAYS = 14;

    @Transactional
    public LibraryTransaction issueBook(IssueBookRequest request) {
        Book book = bookService.getById(request.getBookId());

        if (book.getAvailableCopies() <= 0) {
            throw new BadRequestException("No available copies of '" + book.getTitle() + "'");
        }

        String borrowerType = request.getBorrowerType() == null ? "" : request.getBorrowerType().toUpperCase();
        if (!List.of("STUDENT", "STAFF").contains(borrowerType)) {
            throw new BadRequestException("Borrower type must be STUDENT or STAFF");
        }

        Long borrowerPk = parseBorrowerId(request.getBorrowerId());
        String borrowerName;

        if (borrowerType.equals("STUDENT")) {
            Student student = studentRepository.findById(borrowerPk)
                    .orElseThrow(() -> new ResourceNotFoundException("Student not found: " + request.getBorrowerId()));
            if (!"ACTIVE".equalsIgnoreCase(student.getStatus())) {
                throw new BadRequestException(student.getName() + " is blocked and cannot borrow books");
            }
            if (student.getBorrowedBooksCount() >= student.getBorrowLimit()) {
                throw new BadRequestException(student.getName() + " has reached their borrow limit (" + student.getBorrowLimit() + ")");
            }
            student.setBorrowedBooksCount(student.getBorrowedBooksCount() + 1);
            studentRepository.save(student);
            borrowerName = student.getName();
        } else {
            Staff staff = staffRepository.findById(borrowerPk)
                    .orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + request.getBorrowerId()));
            if (!"ACTIVE".equalsIgnoreCase(staff.getStatus())) {
                throw new BadRequestException(staff.getName() + " is blocked and cannot borrow books");
            }
            if (staff.getBorrowedBooksCount() >= staff.getBorrowLimit()) {
                throw new BadRequestException(staff.getName() + " has reached their borrow limit (" + staff.getBorrowLimit() + ")");
            }
            staff.setBorrowedBooksCount(staff.getBorrowedBooksCount() + 1);
            staffRepository.save(staff);
            borrowerName = staff.getName();
        }

        LocalDateTime now = LocalDateTime.now();
        int duration = request.getDurationDays() == null ? DEFAULT_DURATION_DAYS : request.getDurationDays();

        LibraryTransaction transaction = LibraryTransaction.builder()
                .bookId(book.getId())
                .bookTitle(book.getTitle())
                .borrowerId(request.getBorrowerId())
                .borrowerName(borrowerName)
                .borrowerType(borrowerType)
                .issueDate(now)
                .dueDate(now.plusDays(duration))
                .status("ISSUED")
                .fineAmount(0.0)
                .fineCollected(false)
                .build();

        transaction = transactionRepository.save(transaction);
        bookService.adjustAvailability(book.getId(), -1);
        return transaction;
    }

    @Transactional
    public LibraryTransaction returnBook(ReturnBookRequest request) {
        LibraryTransaction transaction = transactionRepository.findById(request.getTransactionId())
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found: " + request.getTransactionId()));

        if ("RETURNED".equals(transaction.getStatus())) {
            throw new BadRequestException("This book has already been returned");
        }

        LocalDateTime now = LocalDateTime.now();
        long overdueDays = Math.max(0, ChronoUnit.DAYS.between(transaction.getDueDate(), now));
        double fine = overdueDays * FINE_PER_DAY;

        transaction.setReturnDate(now);
        transaction.setStatus("RETURNED");
        transaction.setFineAmount(fine);
        transaction.setFineCollected(request.isFineCollected() || fine == 0);

        transaction = transactionRepository.save(transaction);
        bookService.adjustAvailability(transaction.getBookId(), 1);
        decrementBorrowerCount(transaction.getBorrowerId(), transaction.getBorrowerType());
        return transaction;
    }

    public List<LibraryTransaction> getActiveTransactions() {
        List<LibraryTransaction> issued = transactionRepository.findByStatus("ISSUED");
        List<LibraryTransaction> overdue = transactionRepository.findByStatus("OVERDUE");
        issued.addAll(overdue);
        return issued;
    }

    public List<LibraryTransaction> getAllTransactions() {
        return transactionRepository.findAll();
    }

    /**
     * Flips ISSUED transactions past their due date to OVERDUE.
     * Call this from a scheduled job (see SchedulingConfig) or on-demand
     * before reading dashboard stats.
     */
    @Transactional
    public void refreshOverdueStatuses() {
        LocalDateTime now = LocalDateTime.now();
        for (LibraryTransaction t : transactionRepository.findByStatus("ISSUED")) {
            if (t.getDueDate().isBefore(now)) {
                t.setStatus("OVERDUE");
                transactionRepository.save(t);
            }
        }
    }

    // --- Fine payment status (manual admin update) --------------------------

    /**
     * The admin marks a fine as collected (PAID), still owed (UNPAID), or
     * forgiven (WAIVED) once the student/staff actually pays at the desk.
     * When marking PAID, the admin also records whether it was collected
     * ONLINE (e.g. UPI/bank transfer) or OFFLINE (cash/card at the desk).
     */
    @Transactional
    public LibraryTransaction updateFinePaymentStatus(Long transactionId, String status, String paymentMethod) {
        String normalized = status == null ? "" : status.trim().toUpperCase();
        if (!List.of("PAID", "UNPAID", "WAIVED").contains(normalized)) {
            throw new BadRequestException("Fine status must be PAID, UNPAID, or WAIVED");
        }
        LibraryTransaction transaction = getOrThrow(transactionId);
        transaction.setFinePaymentStatus(normalized);
        transaction.setFineCollected(normalized.equals("PAID") || normalized.equals("WAIVED"));

        if (normalized.equals("PAID")) {
            String method = paymentMethod == null ? "" : paymentMethod.trim().toUpperCase();
            if (!List.of("ONLINE", "OFFLINE").contains(method)) {
                throw new BadRequestException("Payment method must be ONLINE or OFFLINE when marking a fine PAID");
            }
            transaction.setFinePaymentMethod(method);
        } else {
            transaction.setFinePaymentMethod(null);
        }

        return transactionRepository.save(transaction);
    }

    // --- Extension requests --------------------------------------------------

    /** Borrower asks for more time to return a book. Goes to PENDING for admin review. */
    @Transactional
    public LibraryTransaction requestExtension(Long transactionId, Integer extraDays) {
        LibraryTransaction transaction = getOrThrow(transactionId);
        if ("RETURNED".equals(transaction.getStatus())) {
            throw new BadRequestException("This book has already been returned");
        }
        int days = (extraDays == null || extraDays <= 0) ? 7 : extraDays;
        transaction.setRequestedDueDate(transaction.getDueDate().plusDays(days));
        transaction.setExtensionStatus("PENDING");
        return transactionRepository.save(transaction);
    }

    /** Admin approves the extension — the due date is pushed out and the book stays issued. */
    @Transactional
    public LibraryTransaction approveExtension(Long transactionId) {
        LibraryTransaction transaction = getOrThrow(transactionId);
        if (!"PENDING".equals(transaction.getExtensionStatus())) {
            throw new BadRequestException("There is no pending extension request on this transaction");
        }
        transaction.setDueDate(transaction.getRequestedDueDate());
        transaction.setExtensionStatus("APPROVED");
        if ("OVERDUE".equals(transaction.getStatus()) && transaction.getRequestedDueDate().isAfter(LocalDateTime.now())) {
            transaction.setStatus("ISSUED");
        }
        return transactionRepository.save(transaction);
    }

    /** Admin rejects the extension — due date is left unchanged. */
    @Transactional
    public LibraryTransaction rejectExtension(Long transactionId) {
        LibraryTransaction transaction = getOrThrow(transactionId);
        transaction.setExtensionStatus("REJECTED");
        return transactionRepository.save(transaction);
    }

    // --- Manual status override (admin correction) ---------------------------

    /**
     * Lets the admin manually correct a transaction's status — e.g. the
     * borrower physically returned the book at the desk and the admin marks
     * it RETURNED directly, without going through the normal return flow.
     * Book availability and the borrower's borrowed-count are kept
     * consistent with the corrected status.
     */
    @Transactional
    public LibraryTransaction manualStatusUpdate(Long transactionId, String status) {
        String normalized = status == null ? "" : status.trim().toUpperCase();
        if (!List.of("ISSUED", "RETURNED", "OVERDUE", "LOST").contains(normalized)) {
            throw new BadRequestException("Status must be ISSUED, RETURNED, OVERDUE, or LOST");
        }
        LibraryTransaction transaction = getOrThrow(transactionId);
        boolean wasReturned = "RETURNED".equals(transaction.getStatus());
        boolean nowReturned = normalized.equals("RETURNED");

        transaction.setStatus(normalized);
        if (nowReturned && transaction.getReturnDate() == null) {
            transaction.setReturnDate(LocalDateTime.now());
        }
        if (!nowReturned) {
            transaction.setReturnDate(null);
        }

        // Keep the book's available-copy count and the borrower's borrowed-count
        // consistent with the corrected status.
        if (!wasReturned && nowReturned) {
            bookService.adjustAvailability(transaction.getBookId(), 1);
            decrementBorrowerCount(transaction.getBorrowerId(), transaction.getBorrowerType());
        } else if (wasReturned && !nowReturned) {
            bookService.adjustAvailability(transaction.getBookId(), -1);
            incrementBorrowerCount(transaction.getBorrowerId(), transaction.getBorrowerType());
        }

        return transactionRepository.save(transaction);
    }

    private LibraryTransaction getOrThrow(Long transactionId) {
        return transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found: " + transactionId));
    }

    private Long parseBorrowerId(String borrowerId) {
        try {
            return Long.parseLong(borrowerId.trim());
        } catch (NumberFormatException | NullPointerException e) {
            throw new BadRequestException("Invalid borrower id: " + borrowerId);
        }
    }

    private void decrementBorrowerCount(String borrowerId, String borrowerType) {
        Long pk = parseBorrowerId(borrowerId);
        if ("STUDENT".equalsIgnoreCase(borrowerType)) {
            studentRepository.findById(pk).ifPresent(s -> {
                s.setBorrowedBooksCount(Math.max(0, s.getBorrowedBooksCount() - 1));
                studentRepository.save(s);
            });
        } else if ("STAFF".equalsIgnoreCase(borrowerType)) {
            staffRepository.findById(pk).ifPresent(s -> {
                s.setBorrowedBooksCount(Math.max(0, s.getBorrowedBooksCount() - 1));
                staffRepository.save(s);
            });
        }
    }

    private void incrementBorrowerCount(String borrowerId, String borrowerType) {
        Long pk = parseBorrowerId(borrowerId);
        if ("STUDENT".equalsIgnoreCase(borrowerType)) {
            studentRepository.findById(pk).ifPresent(s -> {
                s.setBorrowedBooksCount(s.getBorrowedBooksCount() + 1);
                studentRepository.save(s);
            });
        } else if ("STAFF".equalsIgnoreCase(borrowerType)) {
            staffRepository.findById(pk).ifPresent(s -> {
                s.setBorrowedBooksCount(s.getBorrowedBooksCount() + 1);
                staffRepository.save(s);
            });
        }
    }
}
