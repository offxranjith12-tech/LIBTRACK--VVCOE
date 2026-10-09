package com.vvcoe.libtrack.service;

import com.vvcoe.libtrack.model.Book;
import com.vvcoe.libtrack.model.BorrowRecord;
import com.vvcoe.libtrack.model.BorrowStatus;
import com.vvcoe.libtrack.model.Student;
import com.vvcoe.libtrack.repository.BookRepository;
import com.vvcoe.libtrack.repository.BorrowRecordRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class BorrowService {

    private static final int LOAN_PERIOD_DAYS = 14;
    private static final int MAX_RENEWALS = 2;
    private static final double FINE_PER_DAY = 5.0;

    private final BorrowRecordRepository borrowRecordRepository;
    private final BookRepository bookRepository;
    private final StudentService studentService;

    public BorrowService(BorrowRecordRepository borrowRecordRepository, BookRepository bookRepository,
                          StudentService studentService) {
        this.borrowRecordRepository = borrowRecordRepository;
        this.bookRepository = bookRepository;
        this.studentService = studentService;
    }

    public List<BorrowRecord> getForStudent(Long studentId) {
        List<BorrowRecord> records = borrowRecordRepository.findByStudentIdOrderByBorrowDateDesc(studentId);
        records.forEach(this::refreshOverdueStatus);
        return records;
    }

    public BorrowRecord borrow(Long studentId, Long bookId) {
        Student student = studentService.getById(studentId);
        Book book = bookRepository.findById(bookId)
                .orElseThrow(() -> new ResourceNotFoundException("Book not found: " + bookId));

        if (book.getAvailableCopies() <= 0) {
            throw new IllegalStateException("No copies of \"" + book.getTitle() + "\" are currently available");
        }

        book.setAvailableCopies(book.getAvailableCopies() - 1);
        bookRepository.save(book);

        LocalDateTime now = LocalDateTime.now();
        BorrowRecord record = new BorrowRecord(student, book, now, now.plusDays(LOAN_PERIOD_DAYS));
        return borrowRecordRepository.save(record);
    }

    public BorrowRecord returnBook(Long borrowRecordId) {
        BorrowRecord record = borrowRecordRepository.findById(borrowRecordId)
                .orElseThrow(() -> new ResourceNotFoundException("Borrow record not found: " + borrowRecordId));

        refreshOverdueStatus(record);
        record.setReturnDate(LocalDateTime.now());
        record.setStatus(BorrowStatus.returned);

        Book book = record.getBook();
        book.setAvailableCopies(book.getAvailableCopies() + 1);
        bookRepository.save(book);

        return borrowRecordRepository.save(record);
    }

    public BorrowRecord renew(Long borrowRecordId) {
        BorrowRecord record = borrowRecordRepository.findById(borrowRecordId)
                .orElseThrow(() -> new ResourceNotFoundException("Borrow record not found: " + borrowRecordId));

        if (record.getStatus() == BorrowStatus.returned) {
            throw new IllegalStateException("This book has already been returned");
        }
        if (record.getRenewCount() >= MAX_RENEWALS) {
            throw new IllegalStateException("Maximum renewal limit (" + MAX_RENEWALS + ") reached for this book");
        }

        record.setDueDate(record.getDueDate().plusDays(LOAN_PERIOD_DAYS));
        record.setRenewCount(record.getRenewCount() + 1);
        record.setStatus(BorrowStatus.issued);
        record.setFineAmount(0.0);
        return borrowRecordRepository.save(record);
    }

    /** Recomputes overdue status + fine (₹5/day) for a still-issued record based on today's date. */
    private void refreshOverdueStatus(BorrowRecord record) {
        if (record.getStatus() == BorrowStatus.returned) return;

        LocalDateTime now = LocalDateTime.now();
        if (now.isAfter(record.getDueDate())) {
            long daysLate = ChronoUnit.DAYS.between(record.getDueDate(), now);
            record.setStatus(BorrowStatus.overdue);
            record.setFineAmount(daysLate * FINE_PER_DAY);
            borrowRecordRepository.save(record);
        } else if (record.getStatus() != BorrowStatus.issued) {
            record.setStatus(BorrowStatus.issued);
            record.setFineAmount(0.0);
            borrowRecordRepository.save(record);
        }
    }
}
