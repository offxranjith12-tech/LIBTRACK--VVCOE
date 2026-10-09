package com.vvcoe.libtrack.service;

import com.vvcoe.libtrack.model.BorrowRecord;
import com.vvcoe.libtrack.model.BorrowStatus;
import com.vvcoe.libtrack.repository.BorrowRecordRepository;
import com.vvcoe.libtrack.repository.ReservationRepository;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DashboardService {

    private final BorrowRecordRepository borrowRecordRepository;
    private final ReservationRepository reservationRepository;
    private final BorrowService borrowService;

    public DashboardService(BorrowRecordRepository borrowRecordRepository, ReservationRepository reservationRepository,
                             BorrowService borrowService) {
        this.borrowRecordRepository = borrowRecordRepository;
        this.reservationRepository = reservationRepository;
        this.borrowService = borrowService;
    }

    /**
     * Returns a JSON-friendly map matching the field names the Flutter app's
     * DashboardStats expects: borrowed, reserved, dueSoon, pendingFine,
     * totalBorrowedAllTime, totalReturned, overdueCount.
     */
    public Map<String, Object> getStats(Long studentId) {
        // getForStudent() also refreshes overdue status/fines as a side effect
        List<BorrowRecord> records = borrowService.getForStudent(studentId);

        long issued = records.stream()
                .filter(r -> r.getStatus() == BorrowStatus.issued || r.getStatus() == BorrowStatus.overdue)
                .count();
        long overdue = records.stream().filter(r -> r.getStatus() == BorrowStatus.overdue).count();
        long returned = records.stream().filter(r -> r.getStatus() == BorrowStatus.returned).count();
        long dueSoon = records.stream()
                .filter(r -> r.getStatus() == BorrowStatus.overdue ||
                        (r.getStatus() == BorrowStatus.issued &&
                                java.time.Duration.between(java.time.LocalDateTime.now(), r.getDueDate()).toDays() <= 2))
                .count();
        double pendingFine = records.stream().mapToDouble(BorrowRecord::getFineAmount).sum();
        int reservedCount = reservationRepository.findByStudentIdOrderByReservationDateDesc(studentId).size();

        Map<String, Object> stats = new HashMap<>();
        stats.put("borrowed", issued);
        stats.put("reserved", reservedCount);
        stats.put("dueSoon", dueSoon);
        stats.put("pendingFine", pendingFine);
        stats.put("totalBorrowedAllTime", records.size());
        stats.put("totalReturned", returned);
        stats.put("overdueCount", overdue);
        return stats;
    }
}
