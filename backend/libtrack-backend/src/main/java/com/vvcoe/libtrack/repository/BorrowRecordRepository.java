package com.vvcoe.libtrack.repository;

import com.vvcoe.libtrack.model.BorrowRecord;
import com.vvcoe.libtrack.model.BorrowStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BorrowRecordRepository extends JpaRepository<BorrowRecord, Long> {
    List<BorrowRecord> findByStudentIdOrderByBorrowDateDesc(Long studentId);
    List<BorrowRecord> findByStudentIdAndStatus(Long studentId, BorrowStatus status);
    List<BorrowRecord> findByStatus(BorrowStatus status);
}
