package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.TransactionDto;
import com.vvce.libtrack.entity.Book;
import com.vvce.libtrack.entity.BorrowTransaction;
import com.vvce.libtrack.entity.LibNotification;
import com.vvce.libtrack.entity.Reservation;
import com.vvce.libtrack.entity.Student;
import com.vvce.libtrack.exception.BadRequestException;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.BookRepository;
import com.vvce.libtrack.repository.BorrowTransactionRepository;
import com.vvce.libtrack.repository.NotificationRepository;
import com.vvce.libtrack.repository.ReservationRepository;
import com.vvce.libtrack.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final BorrowTransactionRepository transactionRepository;
    private final BookRepository bookRepository;
    private final StudentRepository studentRepository;
    private final ReservationRepository reservationRepository;
    private final NotificationRepository notificationRepository;

    @Value("${libtrack.borrow.default-loan-days:14}")
    private int defaultLoanDays;

    @Value("${libtrack.fine.per-day-rupees:5}")
    private double finePerDay;

    /** Powers the "Confirm Borrow" button on the Borrow Book screen. Any
     *  staff member can process a borrow/return - this is not restricted
     *  to a "Librarian" designation. */
    @Transactional
    public TransactionDto issueBook(String staffUsername, TransactionDto.IssueRequest request) {
        Student student = studentRepository.findByRegNo(request.studentRegNo())
                .orElseThrow(() -> new ResourceNotFoundException("No student with regNo: " + request.studentRegNo()));
        Book book = bookRepository.findById(request.bookId())
                .orElseThrow(() -> new ResourceNotFoundException("No book with id: " + request.bookId()));

        if (book.getAvailableCopies() == null || book.getAvailableCopies() <= 0) {
            throw new BadRequestException("No available copies of \"" + book.getTitle() + "\" to issue.");
        }
        int borrowLimit = student.getBorrowLimit() == null ? 0 : student.getBorrowLimit();
        int currentBorrowed = student.getCurrentBorrowed() == null ? 0 : student.getCurrentBorrowed();
        if (currentBorrowed >= borrowLimit) {
            throw new BadRequestException(student.getName() + " has reached their borrow limit (" + borrowLimit + ").");
        }

        LocalDate issueDate = request.issueDate() != null ? request.issueDate() : LocalDate.now();
        LocalDate dueDate = request.dueDate() != null ? request.dueDate() : issueDate.plusDays(defaultLoanDays);

        BorrowTransaction txn = BorrowTransaction.builder()
                .book(book)
                .student(student)
                .issueDate(issueDate)
                .dueDate(dueDate)
                .status(BorrowTransaction.Status.ACTIVE)
                .build();
        transactionRepository.save(txn);

        book.setAvailableCopies(book.getAvailableCopies() - 1);
        bookRepository.save(book);

        student.setCurrentBorrowed(currentBorrowed + 1);
        studentRepository.save(student);

        return TransactionDto.from(txn);
    }

    /** Powers the "Return Book" action — resolves the active transaction by
     *  whichever identifier was used (Student ID / Book QR / Book ISBN), then
     *  calculates any overdue fine. */
    @Transactional
    public TransactionDto.ReturnResponse returnBook(TransactionDto.ReturnRequest request) {
        BorrowTransaction txn = resolveActiveTransaction(request);

        LocalDate today = LocalDate.now();
        double fine = 0;
        if (today.isAfter(txn.getDueDate())) {
            long daysLate = ChronoUnit.DAYS.between(txn.getDueDate(), today);
            fine = daysLate * finePerDay;
        }

        txn.setReturnDate(today);
        txn.setFine(fine);
        txn.setStatus(BorrowTransaction.Status.RETURNED);
        transactionRepository.save(txn);

        Book book = txn.getBook();
        book.setAvailableCopies((book.getAvailableCopies() == null ? 0 : book.getAvailableCopies()) + 1);
        bookRepository.save(book);
        notifyNextInQueue(book);

        Student student = txn.getStudent();
        int current = student.getCurrentBorrowed() == null ? 0 : student.getCurrentBorrowed();
        student.setCurrentBorrowed(Math.max(0, current - 1));
        if (fine > 0) {
            student.setFineDue((student.getFineDue() == null ? 0 : student.getFineDue()) + fine);
        }
        studentRepository.save(student);

        return new TransactionDto.ReturnResponse(TransactionDto.from(txn), fine);
    }

    /**
     * Called whenever a copy of a book becomes available (on return). If
     * anyone is waiting in the reservation queue for this book, the
     * earliest one is marked AVAILABLE and staff are alerted so they can
     * hold the copy and inform that student it's ready to be issued.
     */
    private void notifyNextInQueue(Book book) {
        List<Reservation> queue = reservationRepository.findQueueForBook(book.getBookId(), Reservation.Status.WAITING);
        if (queue.isEmpty()) return;

        Reservation reservation = queue.get(0);
        reservation.setStatus(Reservation.Status.AVAILABLE);
        reservationRepository.save(reservation);

        String holderName = reservation.isStaffReservation()
                ? reservation.getStaff().getName() + " (staff)"
                : reservation.getStudent().getName() + " (" + reservation.getStudent().getRegNo() + ")";
        notificationRepository.save(LibNotification.builder()
                .type(LibNotification.Type.RESERVATION)
                .title("Reserved Book Now Available")
                .message("\"" + book.getTitle() + "\" is now available - reserved for " + holderName +
                        ". Hold this copy and notify them.")
                .time(LocalDateTime.now())
                .isRead(false)
                .build());
    }

    /** Powers the "Collect Fine" button. */
    @Transactional
    public TransactionDto collectFine(Long transactionId) {
        BorrowTransaction txn = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("No transaction with id: " + transactionId));

        if (txn.getFine() != null && txn.getFine() > 0 && !Boolean.TRUE.equals(txn.getFineCollected())) {
            Student student = txn.getStudent();
            student.setFineDue(Math.max(0, (student.getFineDue() == null ? 0 : student.getFineDue()) - txn.getFine()));
            studentRepository.save(student);
            txn.setFineCollected(true);
            transactionRepository.save(txn);
        }
        return TransactionDto.from(txn);
    }

    /** Powers "Extend Due Date" — pushes a book's due date out instead of
     *  charging (or continuing to accrue) an overdue fine. Does not touch
     *  the student's currentBorrowed count or availableCopies; the book
     *  stays checked out. */
    @Transactional
    public TransactionDto extendDueDate(Long transactionId, LocalDate newDueDate) {
        BorrowTransaction txn = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("No transaction with id: " + transactionId));

        if (txn.getStatus() != BorrowTransaction.Status.ACTIVE) {
            throw new BadRequestException("Only active borrows can have their due date extended.");
        }
        if (newDueDate == null || !newDueDate.isAfter(txn.getDueDate())) {
            throw new BadRequestException("The new due date must be after the current due date.");
        }

        txn.setDueDate(newDueDate);
        // Extending clears any fine that had already accrued for being overdue
        // up to now — the student is no longer late as of the new due date.
        txn.setFine(0.0);
        txn.setFineCollected(false);
        transactionRepository.save(txn);

        return TransactionDto.from(txn);
    }

    /** Powers the "Active Borrows" list on the Return Book / Transactions screens. */
    public List<TransactionDto> getActiveTransactions() {
        return transactionRepository.findByStatus(BorrowTransaction.Status.ACTIVE)
                .stream().map(TransactionDto::from).toList();
    }

    /** Powers the "History" tab on My Books — previously returned transactions. */
    public List<TransactionDto> getHistoryTransactions() {
        return transactionRepository.findByStatus(BorrowTransaction.Status.RETURNED)
                .stream()
                .sorted((a, b) -> {
                    LocalDate ra = a.getReturnDate();
                    LocalDate rb = b.getReturnDate();
                    if (ra == null || rb == null) return 0;
                    return rb.compareTo(ra); // most recently returned first
                })
                .map(TransactionDto::from).toList();
    }

    private BorrowTransaction resolveActiveTransaction(TransactionDto.ReturnRequest request) {
        List<BorrowTransaction> matches;

        if (request.transactionId() != null && !request.transactionId().isBlank()) {
            BorrowTransaction txn = transactionRepository.findById(Long.parseLong(request.transactionId()))
                    .orElseThrow(() -> new ResourceNotFoundException("No transaction with id: " + request.transactionId()));
            return txn;
        } else if (request.bookIsbn() != null && !request.bookIsbn().isBlank()) {
            matches = transactionRepository.findActiveByIsbn(request.bookIsbn());
        } else if (request.bookQrCode() != null && !request.bookQrCode().isBlank()) {
            // QR payload is expected to encode the ISBN — adjust if your QR format differs.
            matches = transactionRepository.findActiveByIsbn(request.bookQrCode());
        } else if (request.studentRegNo() != null && !request.studentRegNo().isBlank()) {
            matches = transactionRepository.findActiveByStudent(request.studentRegNo());
        } else {
            throw new BadRequestException("Provide a transaction id, student ID, book ISBN, or book QR code to return.");
        }

        if (matches.isEmpty()) {
            throw new ResourceNotFoundException("No active borrow found for the given search.");
        }
        return matches.get(0);
    }
}
