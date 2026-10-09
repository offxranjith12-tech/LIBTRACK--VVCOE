package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.Reservation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ReservationRepository extends JpaRepository<Reservation, Long> {

    List<Reservation> findByStatusInOrderByQueuePositionAsc(List<Reservation.Status> statuses);

    long countByStatusIn(List<Reservation.Status> statuses);

    @Query("SELECT r FROM Reservation r WHERE r.student.regNo = :regNo ORDER BY r.reservedOn DESC")
    List<Reservation> findByStudent(@Param("regNo") String regNo);

    /** Powers the staff module's "My Reservations" list — only this staff member's own, still-active reservations. */
    @Query("SELECT r FROM Reservation r WHERE r.staff.staffId = :staffId AND r.status IN ('WAITING','AVAILABLE','APPROVED') " +
           "ORDER BY r.reservedOn DESC")
    List<Reservation> findActiveByStaff(@Param("staffId") String staffId);

    @Query("SELECT r FROM Reservation r WHERE r.staff.staffId = :staffId AND r.status IN ('CANCELLED', 'FULFILLED') " +
           "ORDER BY r.reservedOn DESC")
    List<Reservation> findHistoryByStaff(@Param("staffId") String staffId);

    @Query("SELECT COALESCE(MAX(r.queuePosition), 0) FROM Reservation r WHERE r.book.bookId = :bookId " +
           "AND r.status IN ('WAITING','AVAILABLE')")
    Integer findMaxQueuePositionForBook(@Param("bookId") String bookId);

    /**
     * Used when a book is returned, to find who's next in line for it.
     * Staff reservations (priority 0) are served ahead of student reservations (priority 1);
     * within the same priority, earliest queue position wins.
     */
    @Query("SELECT r FROM Reservation r WHERE r.book.bookId = :bookId AND r.status = :status " +
           "ORDER BY r.priority ASC, r.queuePosition ASC")
    List<Reservation> findQueueForBook(@Param("bookId") String bookId, @Param("status") Reservation.Status status);
}
