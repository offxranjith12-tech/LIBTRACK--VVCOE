package com.vvcoe.libtrack.service;

import com.vvcoe.libtrack.model.Book;
import com.vvcoe.libtrack.model.Reservation;
import com.vvcoe.libtrack.model.Student;
import com.vvcoe.libtrack.repository.BookRepository;
import com.vvcoe.libtrack.repository.ReservationRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ReservationService {

    private final ReservationRepository reservationRepository;
    private final BookRepository bookRepository;
    private final StudentService studentService;

    public ReservationService(ReservationRepository reservationRepository, BookRepository bookRepository,
                               StudentService studentService) {
        this.reservationRepository = reservationRepository;
        this.bookRepository = bookRepository;
        this.studentService = studentService;
    }

    public List<Reservation> getForStudent(Long studentId) {
        return reservationRepository.findByStudentIdOrderByReservationDateDesc(studentId);
    }

    public Reservation create(Long studentId, Long bookId) {
        Student student = studentService.getById(studentId);
        Book book = bookRepository.findById(bookId)
                .orElseThrow(() -> new ResourceNotFoundException("Book not found: " + bookId));

        int position = reservationRepository.findByBookIdOrderByQueuePositionAsc(bookId).size() + 1;
        LocalDateTime expected = LocalDateTime.now().plusDays(3L * position);

        Reservation reservation = new Reservation(student, book, LocalDateTime.now(), position, expected);
        return reservationRepository.save(reservation);
    }

    public void cancel(Long reservationId) {
        if (!reservationRepository.existsById(reservationId)) {
            throw new ResourceNotFoundException("Reservation not found: " + reservationId);
        }
        reservationRepository.deleteById(reservationId);
    }
}
