package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.StatsDtos;
import com.vvce.libtrack.entity.BorrowTransaction;
import com.vvce.libtrack.entity.Reservation;
import com.vvce.libtrack.repository.BorrowTransactionRepository;
import com.vvce.libtrack.repository.ReservationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final BorrowTransactionRepository transactionRepository;
    private final ReservationRepository reservationRepository;

    /** Backs the 4 stat cards on the Staff Dashboard screen. */
    public StatsDtos.DashboardStats getStats() {
        LocalDate today = LocalDate.now();

        long borrowedBooks = transactionRepository.findByStatus(BorrowTransaction.Status.ACTIVE).size();
        long returnedBooks = transactionRepository.findByStatus(BorrowTransaction.Status.RETURNED).size();
        long dueSoon = transactionRepository.countDueSoon(today.plusDays(3));
        long reservedBooks = reservationRepository.countByStatusIn(List.of(Reservation.Status.WAITING, Reservation.Status.AVAILABLE));

        return new StatsDtos.DashboardStats(
                borrowedBooks,
                returnedBooks,
                dueSoon,
                reservedBooks,
                borrowedBooks, // issuedToday fallback
                returnedBooks, // returnedToday fallback
                dueSoon,       // pendingReturns fallback
                reservedBooks  // activeBorrowers fallback
        );
    }
}
