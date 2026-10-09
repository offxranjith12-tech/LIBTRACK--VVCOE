package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.LibraryTransaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TransactionRepository extends JpaRepository<LibraryTransaction, Long> {
    List<LibraryTransaction> findByStatus(String status);
    List<LibraryTransaction> findByBorrowerId(String borrowerId);
    List<LibraryTransaction> findByBookIdAndStatus(Long bookId, String status);
}
