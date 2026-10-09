package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ApiResponse;
import com.vvce.libtrack.dto.CreateBookRequestDto;
import com.vvce.libtrack.dto.RejectBookRequestDto;
import com.vvce.libtrack.entity.BookRequest;
import com.vvce.libtrack.service.BookRequestService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/book-requests")
@RequiredArgsConstructor
public class BookRequestController {

    private final BookRequestService bookRequestService;

    /** Student (or admin on a student's behalf) requests a book. */
    @PostMapping
    public ApiResponse<BookRequest> create(@Valid @RequestBody CreateBookRequestDto dto) {
        return ApiResponse.ok("Book request submitted", bookRequestService.createRequest(dto));
    }

    /** Admin's requests inbox — optionally filtered by status (PENDING, APPROVED, REJECTED, ISSUED). */
    @GetMapping
    public ApiResponse<List<BookRequest>> getAll(@RequestParam(required = false) String status) {
        List<BookRequest> requests = (status == null || status.isBlank())
                ? bookRequestService.getAll()
                : bookRequestService.getByStatus(status);
        return ApiResponse.ok(requests);
    }

    /** A specific student's own request history. */
    @GetMapping("/student/{studentId}")
    public ApiResponse<List<BookRequest>> getByStudent(@PathVariable String studentId) {
        return ApiResponse.ok(bookRequestService.getByStudent(studentId));
    }

    /** Admin verifies eligibility and issues the book in one step. */
    @PostMapping("/{id}/approve")
    public ApiResponse<BookRequest> approve(@PathVariable Long id, @RequestParam(required = false) Integer durationDays) {
        return ApiResponse.ok("Request approved and book issued", bookRequestService.approveAndIssue(id, durationDays));
    }

    @PostMapping("/{id}/reject")
    public ApiResponse<BookRequest> reject(@PathVariable Long id, @RequestBody(required = false) RejectBookRequestDto dto) {
        String reason = dto == null ? null : dto.getReason();
        return ApiResponse.ok("Request rejected", bookRequestService.reject(id, reason));
    }
}
