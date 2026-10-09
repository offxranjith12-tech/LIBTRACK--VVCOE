package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.TransactionDto;
import com.vvce.libtrack.service.TransactionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Backs the Issue Book and Return Book screens, plus the Transactions tab. */
@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;

    /** "Confirm Issue" button — librarian-only, enforced in the service layer. */
    @PostMapping("/issue")
    public TransactionDto issue(Authentication auth, @Valid @RequestBody TransactionDto.IssueRequest request) {
        return transactionService.issueBook(auth.getName(), request);
    }

    /** "Return Book" button. */
    @PostMapping("/return")
    public TransactionDto.ReturnResponse returnBook(@RequestBody TransactionDto.ReturnRequest request) {
        return transactionService.returnBook(request);
    }

    /** "Collect Fine" button. */
    @PostMapping("/{id}/collect-fine")
    public TransactionDto collectFine(@PathVariable Long id) {
        return transactionService.collectFine(id);
    }

    /** "Extend Due Date" button — lets staff push a due date out for a
     *  student instead of the book accruing an overdue fine. */
    @PostMapping("/{id}/extend")
    public TransactionDto extend(@PathVariable Long id, @RequestBody TransactionDto.ExtendRequest request) {
        return transactionService.extendDueDate(id, request.newDueDate());
    }

    /** "Active Borrows" list on Return Book / Transactions screens. */
    @GetMapping("/active")
    public List<TransactionDto> getActive() {
        return transactionService.getActiveTransactions();
    }

    /** "History" tab on My Books — previously returned transactions. */
    @GetMapping("/history")
    public List<TransactionDto> getHistory() {
        return transactionService.getHistoryTransactions();
    }
}
