package com.vvcoe.libtrack.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "reservations")
public class Reservation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @Column(nullable = false)
    private LocalDateTime reservationDate;

    @Column(nullable = false)
    private Integer queuePosition = 1;

    @Column(nullable = false)
    private LocalDateTime expectedAvailability;

    public Reservation() {
    }

    public Reservation(Student student, Book book, LocalDateTime reservationDate,
                        Integer queuePosition, LocalDateTime expectedAvailability) {
        this.student = student;
        this.book = book;
        this.reservationDate = reservationDate;
        this.queuePosition = queuePosition;
        this.expectedAvailability = expectedAvailability;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Student getStudent() {
        return student;
    }

    public void setStudent(Student student) {
        this.student = student;
    }

    public Book getBook() {
        return book;
    }

    public void setBook(Book book) {
        this.book = book;
    }

    public LocalDateTime getReservationDate() {
        return reservationDate;
    }

    public void setReservationDate(LocalDateTime reservationDate) {
        this.reservationDate = reservationDate;
    }

    public Integer getQueuePosition() {
        return queuePosition;
    }

    public void setQueuePosition(Integer queuePosition) {
        this.queuePosition = queuePosition;
    }

    public LocalDateTime getExpectedAvailability() {
        return expectedAvailability;
    }

    public void setExpectedAvailability(LocalDateTime expectedAvailability) {
        this.expectedAvailability = expectedAvailability;
    }
}
