package com.vvcoe.libtrack.controller;

import com.vvcoe.libtrack.model.Reservation;
import com.vvcoe.libtrack.service.ReservationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ReservationController {

    private final ReservationService reservationService;

    public ReservationController(ReservationService reservationService) {
        this.reservationService = reservationService;
    }

    @GetMapping("/students/{studentId}/reservations")
    public ResponseEntity<List<Reservation>> getForStudent(@PathVariable Long studentId) {
        return ResponseEntity.ok(reservationService.getForStudent(studentId));
    }

    @PostMapping("/reservations")
    public ResponseEntity<Reservation> create(@RequestBody Map<String, Long> body) {
        Reservation reservation = reservationService.create(body.get("studentId"), body.get("bookId"));
        return ResponseEntity.ok(reservation);
    }

    @DeleteMapping("/reservations/{id}")
    public ResponseEntity<Void> cancel(@PathVariable Long id) {
        reservationService.cancel(id);
        return ResponseEntity.noContent().build();
    }
}
