package com.vvcoe.libtrack.repository;

import com.vvcoe.libtrack.model.Reservation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReservationRepository extends JpaRepository<Reservation, Long> {
    List<Reservation> findByStudentIdOrderByReservationDateDesc(Long studentId);
    List<Reservation> findByBookIdOrderByQueuePositionAsc(Long bookId);
}
