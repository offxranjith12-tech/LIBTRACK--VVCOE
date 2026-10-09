package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.ReservationDto;
import com.vvce.libtrack.entity.Book;
import com.vvce.libtrack.entity.LibNotification;
import com.vvce.libtrack.entity.Reservation;
import com.vvce.libtrack.entity.Staff;
import com.vvce.libtrack.entity.Student;
import com.vvce.libtrack.exception.BadRequestException;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.BookRepository;
import com.vvce.libtrack.repository.NotificationRepository;
import com.vvce.libtrack.repository.ReservationRepository;
import com.vvce.libtrack.repository.StaffRepository;
import com.vvce.libtrack.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReservationService {

    private final ReservationRepository reservationRepository;
    private final NotificationRepository notificationRepository;
    private final BookRepository bookRepository;
    private final StudentRepository studentRepository;
    private final StaffRepository staffRepository;

    /** Powers the Reservations screen list. */
    public List<ReservationDto> getAll() {
        return reservationRepository
                .findByStatusInOrderByQueuePositionAsc(List.of(Reservation.Status.WAITING, Reservation.Status.AVAILABLE))
                .stream().map(ReservationDto::from).toList();
    }

    /**
     * Powers the staff module's "My Reservations" list — only the logged-in
     * staff member's own reservations that are still active (waiting in the
     * queue, or available and waiting to be collected). Once a staff member
     * marks a reservation collected, it drops off this list.
     */
    public List<ReservationDto> getForStaff(String staffUsername) {
        Staff staff = staffRepository.findByUsername(staffUsername)
                .orElseThrow(() -> new ResourceNotFoundException("No staff account for username: " + staffUsername));
        return reservationRepository.findActiveByStaff(staff.getStaffId())
                .stream().map(ReservationDto::from).toList();
    }

    public List<ReservationDto> getHistoryForStaff(String staffUsername) {
        Staff staff = staffRepository.findByUsername(staffUsername)
                .orElseThrow(() -> new ResourceNotFoundException("No staff account for username: " + staffUsername));
        return reservationRepository.findHistoryByStaff(staff.getStaffId())
                .stream().map(ReservationDto::from).toList();
    }

    /**
     * Powers the staff module's "Reserve" / "Join Queue" action — a staff
     * member reserving a book for themselves (not on behalf of a student).
     * If a copy is free right now, it's held immediately (marked AVAILABLE
     * and the copy count is reduced) so the staff member can go collect it.
     * Otherwise they join the queue with priority over student reservations.
     */
    @Transactional
    public ReservationDto reserveForStaff(String bookId, String staffUsername) {
        Book book = bookRepository.findById(bookId)
                .orElseThrow(() -> new ResourceNotFoundException("No book with id: " + bookId));
        Staff staff = staffRepository.findByUsername(staffUsername)
                .orElseThrow(() -> new ResourceNotFoundException("No staff account for username: " + staffUsername));

        boolean copyFree = book.getAvailableCopies() != null && book.getAvailableCopies() > 0;

        Reservation.ReservationBuilder builder = Reservation.builder()
                .book(book)
                .staff(staff)
                .reservedOn(LocalDateTime.now())
                .priority(0);

        Reservation reservation;
        if (copyFree) {
            book.setAvailableCopies(book.getAvailableCopies() - 1);
            bookRepository.save(book);
            reservation = builder.status(Reservation.Status.AVAILABLE)
                    .queuePosition(0)
                    .build();
        } else {
            int nextPosition = reservationRepository.findMaxQueuePositionForBook(bookId) + 1;
            reservation = builder.status(Reservation.Status.WAITING)
                    .queuePosition(nextPosition)
                    .build();
        }
        reservationRepository.save(reservation);

        // Notify staff automatically when reservation is created
        notificationRepository.save(LibNotification.builder()
                .type(LibNotification.Type.RESERVATION)
                .title(copyFree ? "Reservation Confirmed" : "Joined Queue #" + reservation.getQueuePosition())
                .message(copyFree
                        ? "Your reservation for \"" + book.getTitle() + "\" is confirmed and ready for pickup."
                        : "Your reservation for \"" + book.getTitle() + "\" has been added to queue at #" + reservation.getQueuePosition() + ".")
                .time(LocalDateTime.now())
                .isRead(false)
                .build());

        return ReservationDto.from(reservation);
    }

    /** "Mark Collected" — staff has picked up the held copy from the library counter. */
    @Transactional
    public ReservationDto collect(Long id, String staffUsername) {
        Reservation r = findById(id);
        if (!r.isStaffReservation() || !r.getStaff().getUsername().equals(staffUsername)) {
            throw new BadRequestException("This reservation does not belong to you.");
        }
        if (r.getStatus() != Reservation.Status.AVAILABLE) {
            throw new BadRequestException("This book isn't available to collect yet.");
        }
        r.setStatus(Reservation.Status.APPROVED);
        reservationRepository.save(r);
        return ReservationDto.from(r);
    }

    /**
     * Powers the Join Queue screen — a staff member reserving an
     * unavailable book on behalf of a student. Queue position is
     * computed as one past whatever the current highest position is for
     * that book among still-active (WAITING/AVAILABLE) reservations.
     */
    @Transactional
    public ReservationDto create(String bookId, String studentRegNo) {
        Book book = bookRepository.findById(bookId)
                .orElseThrow(() -> new ResourceNotFoundException("No book with id: " + bookId));
        Student student = studentRepository.findById(studentRegNo)
                .orElseThrow(() -> new ResourceNotFoundException("No student with register number: " + studentRegNo));

        if (book.getAvailableCopies() != null && book.getAvailableCopies() > 0) {
            throw new BadRequestException("This book currently has copies available - no need to join the queue.");
        }

        int nextPosition = reservationRepository.findMaxQueuePositionForBook(bookId) + 1;

        Reservation reservation = Reservation.builder()
                .book(book)
                .student(student)
                .reservedOn(LocalDateTime.now())
                .queuePosition(nextPosition)
                .status(Reservation.Status.WAITING)
                .build();
        reservationRepository.save(reservation);
        return ReservationDto.from(reservation);
    }

    /** Powers the "Approve" button — only allowed once the book is marked available. */
    @Transactional
    public ReservationDto approve(Long id) {
        Reservation r = findById(id);
        if (r.getStatus() != Reservation.Status.AVAILABLE) {
            throw new BadRequestException("Reservation is still in queue and cannot be approved yet.");
        }
        r.setStatus(Reservation.Status.APPROVED);
        reservationRepository.save(r);
        return ReservationDto.from(r);
    }

    /** Powers the "Cancel" button. If a copy was being held (status AVAILABLE), it's released back to the shelf. */
    @Transactional
    public ReservationDto cancel(Long id) {
        Reservation r = findById(id);
        if (r.getStatus() == Reservation.Status.AVAILABLE) {
            Book book = r.getBook();
            book.setAvailableCopies((book.getAvailableCopies() == null ? 0 : book.getAvailableCopies()) + 1);
            bookRepository.save(book);
        }
        r.setStatus(Reservation.Status.CANCELLED);
        reservationRepository.save(r);
        return ReservationDto.from(r);
    }

    /** Powers the "Notify Student" button — creates a reservation notification. */
    @Transactional
    public void notifyStudent(Long id) {
        Reservation r = findById(id);
        notificationRepository.save(LibNotification.builder()
                .type(LibNotification.Type.RESERVATION)
                .title("Reservation Update")
                .message("\"" + r.getBook().getTitle() + "\" reservation status updated for " +
                        (r.getStudent() != null ? r.getStudent().getName() : r.getStaff().getName()) + ".")
                .time(LocalDateTime.now())
                .isRead(false)
                .build());
    }

    private Reservation findById(Long id) {
        return reservationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("No reservation with id: " + id));
    }
}
