package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.CreateBookRequestDto;
import com.vvce.libtrack.dto.IssueBookRequest;
import com.vvce.libtrack.entity.Book;
import com.vvce.libtrack.entity.BookRequest;
import com.vvce.libtrack.entity.LibraryTransaction;
import com.vvce.libtrack.entity.Student;
import com.vvce.libtrack.exception.BadRequestException;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.BookRequestRepository;
import com.vvce.libtrack.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * A student requests a specific book (e.g. from the catalogue), the admin
 * reviews it here, and either rejects it or issues the copy directly —
 * which reuses {@link TransactionService#issueBook} so borrow-limit /
 * availability checks stay in exactly one place.
 */
@Service
@RequiredArgsConstructor
public class BookRequestService {

    private final BookRequestRepository bookRequestRepository;
    private final StudentRepository studentRepository;
    private final BookService bookService;
    private final TransactionService transactionService;

    @Transactional
    public BookRequest createRequest(CreateBookRequestDto dto) {
        Book book = bookService.getById(dto.getBookId());
        Student student = getStudentOrThrow(dto.getStudentId());

        BookRequest request = BookRequest.builder()
                .bookId(book.getId())
                .bookTitle(book.getTitle())
                .studentId(dto.getStudentId())
                .studentName(student.getName())
                .department(student.getDepartment())
                .status("PENDING")
                .requestedAt(LocalDateTime.now())
                .notes(dto.getNotes())
                .build();

        return bookRequestRepository.save(request);
    }

    public List<BookRequest> getAll() {
        return bookRequestRepository.findAllByOrderByRequestedAtDesc();
    }

    public List<BookRequest> getByStatus(String status) {
        return bookRequestRepository.findByStatusOrderByRequestedAtDesc(status.toUpperCase());
    }

    public List<BookRequest> getByStudent(String studentId) {
        return bookRequestRepository.findByStudentIdOrderByRequestedAtDesc(studentId);
    }

    /** Admin verifies eligibility and issues the book in one step. */
    @Transactional
    public BookRequest approveAndIssue(Long requestId, Integer durationDays) {
        BookRequest request = getOrThrow(requestId);
        if (!"PENDING".equals(request.getStatus())) {
            throw new BadRequestException("This request has already been " + request.getStatus().toLowerCase());
        }

        Student student = getStudentOrThrow(request.getStudentId());
        if (student.getBorrowedBooksCount() != null && student.getBorrowLimit() != null
                && student.getBorrowedBooksCount() >= student.getBorrowLimit()) {
            throw new BadRequestException(student.getName() + " has reached their borrow limit ("
                    + student.getBorrowLimit() + " books). Resolve returns/fines before issuing.");
        }

        IssueBookRequest issueRequest = new IssueBookRequest();
        issueRequest.setBookId(request.getBookId());
        issueRequest.setBorrowerId(request.getStudentId());
        issueRequest.setBorrowerType("STUDENT");
        issueRequest.setDurationDays(durationDays);

        LibraryTransaction transaction = transactionService.issueBook(issueRequest);

        request.setStatus("ISSUED");
        request.setDecidedAt(LocalDateTime.now());
        request.setTransactionId(transaction.getId());
        return bookRequestRepository.save(request);
    }

    @Transactional
    public BookRequest reject(Long requestId, String reason) {
        BookRequest request = getOrThrow(requestId);
        if (!"PENDING".equals(request.getStatus())) {
            throw new BadRequestException("This request has already been " + request.getStatus().toLowerCase());
        }
        request.setStatus("REJECTED");
        request.setDecidedAt(LocalDateTime.now());
        request.setRejectionReason(reason == null || reason.isBlank() ? "Not approved by library staff" : reason);
        return bookRequestRepository.save(request);
    }

    private BookRequest getOrThrow(Long id) {
        return bookRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Book request not found: " + id));
    }

    private Student getStudentOrThrow(String studentId) {
        try {
            return studentRepository.findById(Long.parseLong(studentId))
                    .orElseThrow(() -> new ResourceNotFoundException("Student not found: " + studentId));
        } catch (NumberFormatException e) {
            throw new BadRequestException("Invalid student id: " + studentId);
        }
    }
}
