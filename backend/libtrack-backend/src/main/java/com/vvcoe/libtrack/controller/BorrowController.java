package com.vvcoe.libtrack.controller;

import com.vvcoe.libtrack.model.BorrowRecord;
import com.vvcoe.libtrack.service.BorrowService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class BorrowController {

    private final BorrowService borrowService;

    public BorrowController(BorrowService borrowService) {
        this.borrowService = borrowService;
    }

    /** Matches ApiService.fetchBorrowedBooks() in the Flutter app. */
    @GetMapping("/students/{studentId}/borrowed-books")
    public ResponseEntity<List<BorrowRecord>> getBorrowedBooks(@PathVariable Long studentId) {
        return ResponseEntity.ok(borrowService.getForStudent(studentId));
    }

    /** Librarian-counter action: issue a book to a student. */
    @PostMapping("/borrow")
    public ResponseEntity<BorrowRecord> borrow(@RequestBody Map<String, Long> body) {
        BorrowRecord record = borrowService.borrow(body.get("studentId"), body.get("bookId"));
        return ResponseEntity.ok(record);
    }

    /** Matches ApiService.renewBorrowedBook() in the Flutter app. */
    @PostMapping("/borrowed-books/{id}/renew")
    public ResponseEntity<BorrowRecord> renew(@PathVariable Long id) {
        return ResponseEntity.ok(borrowService.renew(id));
    }

    /** Librarian-counter action: mark a book as returned. */
    @PostMapping("/borrowed-books/{id}/return")
    public ResponseEntity<BorrowRecord> returnBook(@PathVariable Long id) {
        return ResponseEntity.ok(borrowService.returnBook(id));
    }
}
