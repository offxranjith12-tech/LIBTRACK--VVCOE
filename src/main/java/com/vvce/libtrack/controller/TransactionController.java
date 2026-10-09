package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ApiResponse;
import com.vvce.libtrack.dto.ExtensionRequestDto;
import com.vvce.libtrack.dto.FineStatusUpdateRequest;
import com.vvce.libtrack.dto.IssueBookRequest;
import com.vvce.libtrack.dto.ManualStatusUpdateRequest;
import com.vvce.libtrack.dto.ReturnBookRequest;
import com.vvce.libtrack.entity.LibraryTransaction;
import com.vvce.libtrack.service.TransactionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;

    @GetMapping
    public ApiResponse<List<LibraryTransaction>> getAll() {
        transactionService.refreshOverdueStatuses();
        return ApiResponse.ok(transactionService.getAllTransactions());
    }

    @GetMapping("/active")
    public ApiResponse<List<LibraryTransaction>> getActive() {
        transactionService.refreshOverdueStatuses();
        return ApiResponse.ok(transactionService.getActiveTransactions());
    }

    @PostMapping("/issue")
    public ApiResponse<LibraryTransaction> issue(@Valid @RequestBody IssueBookRequest request) {
        return ApiResponse.ok("Book issued", transactionService.issueBook(request));
    }

    @PostMapping("/return")
    public ApiResponse<LibraryTransaction> returnBook(@Valid @RequestBody ReturnBookRequest request) {
        return ApiResponse.ok("Book returned", transactionService.returnBook(request));
    }

    /** Admin marks a fine as PAID / UNPAID / WAIVED — reflected on the borrower's profile. */
    @PatchMapping("/{id}/fine-status")
    public ApiResponse<LibraryTransaction> updateFineStatus(@PathVariable Long id, @Valid @RequestBody FineStatusUpdateRequest request) {
        return ApiResponse.ok("Fine status updated", transactionService.updateFinePaymentStatus(id, request.getStatus(), request.getPaymentMethod()));
    }

    /** Borrower (student/staff) requests more time to return a book. */
    @PostMapping("/extension/request")
    public ApiResponse<LibraryTransaction> requestExtension(@Valid @RequestBody ExtensionRequestDto request) {
        return ApiResponse.ok("Extension requested", transactionService.requestExtension(request.getTransactionId(), request.getExtraDays()));
    }

    /** Admin approves a pending extension request. */
    @PatchMapping("/{id}/extension/approve")
    public ApiResponse<LibraryTransaction> approveExtension(@PathVariable Long id) {
        return ApiResponse.ok("Extension approved", transactionService.approveExtension(id));
    }

    /** Admin rejects a pending extension request. */
    @PatchMapping("/{id}/extension/reject")
    public ApiResponse<LibraryTransaction> rejectExtension(@PathVariable Long id) {
        return ApiResponse.ok("Extension rejected", transactionService.rejectExtension(id));
    }

    /** Admin manually corrects a transaction's status (e.g. desk return not scanned via QR). */
    @PatchMapping("/{id}/manual-status")
    public ApiResponse<LibraryTransaction> manualStatusUpdate(@PathVariable Long id, @Valid @RequestBody ManualStatusUpdateRequest request) {
        return ApiResponse.ok("Transaction status updated", transactionService.manualStatusUpdate(id, request.getStatus()));
    }
}
