package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.BorrowTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface BorrowTransactionRepository extends JpaRepository<BorrowTransaction, Long> {

    List<BorrowTransaction> findByStatus(BorrowTransaction.Status status);

    long countByStatusAndIssueDate(BorrowTransaction.Status status, LocalDate issueDate);

    long countByReturnDate(LocalDate returnDate);

    @Query("SELECT COUNT(t) FROM BorrowTransaction t WHERE t.status = 'ACTIVE' AND t.dueDate <= :threshold")
    long countDueSoon(@Param("threshold") LocalDate threshold);

    @Query("SELECT COUNT(t) FROM BorrowTransaction t WHERE t.status = 'ACTIVE' AND t.dueDate < :today")
    long countOverdue(@Param("today") LocalDate today);

    @Query("SELECT COUNT(DISTINCT t.student.regNo) FROM BorrowTransaction t WHERE t.status = 'ACTIVE'")
    long countActiveBorrowers();

    @Query("SELECT t FROM BorrowTransaction t WHERE t.status = 'ACTIVE' AND t.student.regNo = :regNo")
    List<BorrowTransaction> findActiveByStudent(@Param("regNo") String regNo);

    @Query("SELECT t FROM BorrowTransaction t WHERE t.status = 'ACTIVE' AND t.book.bookId = :bookId AND t.student.regNo = :regNo")
    List<BorrowTransaction> findActiveByStudentAndBook(@Param("regNo") String regNo, @Param("bookId") String bookId);

    @Query("SELECT t FROM BorrowTransaction t WHERE t.status = 'ACTIVE' AND t.book.isbn = :isbn")
    List<BorrowTransaction> findActiveByIsbn(@Param("isbn") String isbn);

    List<BorrowTransaction> findByStudentRegNoOrderByIssueDateDesc(String regNo);
}
