package com.vvce.libtrack.controller;

import com.vvce.libtrack.entity.LibraryTransaction;
import com.vvce.libtrack.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.ByteArrayOutputStream;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Generates the downloadable transactions report shown on the Reports screen.
 * Kept intentionally simple (CSV, opens straight into Excel/Sheets) so it
 * works out of the box without extra PDF-rendering dependencies server-side —
 * the app can still turn this into a PDF client-side via the pdf skill if
 * needed.
 */
@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
public class ReportController {

    private final TransactionRepository transactionRepository;
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    @GetMapping("/transactions/download")
    public ResponseEntity<byte[]> downloadTransactionsReport(@RequestParam(required = false) String status) {
        List<LibraryTransaction> transactions = (status == null || status.isBlank())
                ? transactionRepository.findAll()
                : transactionRepository.findByStatus(status.toUpperCase());

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try (PrintWriter writer = new PrintWriter(out, true, StandardCharsets.UTF_8)) {
            writer.println("Transaction ID,Book Title,Borrower Name,Borrower Type,Issue Date,Due Date,Return Date,Status,Fine Amount,Fine Payment Status");
            for (LibraryTransaction t : transactions) {
                writer.printf("%d,%s,%s,%s,%s,%s,%s,%s,%.2f,%s%n",
                        t.getId(),
                        csvSafe(t.getBookTitle()),
                        csvSafe(t.getBorrowerName()),
                        t.getBorrowerType(),
                        t.getIssueDate() == null ? "" : t.getIssueDate().format(FMT),
                        t.getDueDate() == null ? "" : t.getDueDate().format(FMT),
                        t.getReturnDate() == null ? "" : t.getReturnDate().format(FMT),
                        t.getStatus(),
                        t.getFineAmount() == null ? 0.0 : t.getFineAmount(),
                        t.getFinePaymentStatus());
            }
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentDisposition(org.springframework.http.ContentDisposition
                .attachment().filename("libtrack-transactions-report.csv").build());
        return ResponseEntity.ok()
                .headers(headers)
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(out.toByteArray());
    }

    private String csvSafe(String value) {
        if (value == null) return "";
        String escaped = value.replace("\"", "\"\"");
        return escaped.contains(",") ? "\"" + escaped + "\"" : escaped;
    }
}
