package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ApiResponse;
import com.vvce.libtrack.repository.StaffRepository;
import com.vvce.libtrack.repository.StudentRepository;
import com.vvce.libtrack.repository.TransactionRepository;
import com.vvce.libtrack.service.BookService;
import com.vvce.libtrack.service.TransactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final BookService bookService;
    private final StudentRepository studentRepository;
    private final StaffRepository staffRepository;
    private final TransactionRepository transactionRepository;
    private final TransactionService transactionService;

    @GetMapping("/stats")
    public ApiResponse<Map<String, Object>> stats() {
        transactionService.refreshOverdueStatuses();

        long totalBooks = bookService.totalBookCount();
        long availableBooks = bookService.availableBookCount();
        long overdueCount = transactionRepository.findByStatus("OVERDUE").size();
        double fineCollected = transactionRepository.findAll().stream()
                .filter(t -> Boolean.TRUE.equals(t.getFineCollected()))
                .mapToDouble(t -> t.getFineAmount() == null ? 0 : t.getFineAmount())
                .sum();

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalBooks", totalBooks);
        stats.put("availableBooks", availableBooks);
        stats.put("issuedBooks", totalBooks - availableBooks);
        stats.put("totalStudents", studentRepository.count());
        stats.put("totalStaff", staffRepository.count());
        stats.put("overdueBooks", overdueCount);
        stats.put("fineCollection", fineCollected);

        return ApiResponse.ok(stats);
    }
}
