package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ReservationDto;
import com.vvce.libtrack.service.ReservationService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** Backs the Reservations screen and the Join Queue flow from Book Details / Search. */
@RestController
@RequestMapping("/api/reservations")
@RequiredArgsConstructor
public class ReservationController {

    private final ReservationService reservationService;

    @GetMapping
    public List<ReservationDto> getAll() {
        return reservationService.getAll();
    }

    /** Staff module's "My Reservations" list — only the logged-in staff member's own active reservations. */
    @GetMapping("/mine")
    public List<ReservationDto> getMine(Authentication auth) {
        return reservationService.getForStaff(auth.getName());
    }

    /** Staff module's history of reservations (cancelled/fulfilled). */
    @GetMapping("/mine/history")
    public List<ReservationDto> getMineHistory(Authentication auth) {
        return reservationService.getHistoryForStaff(auth.getName());
    }

    /** Join Queue screen — staff reserving an unavailable book for a student. */
    @PostMapping
    public ReservationDto create(@RequestBody Map<String, String> body) {
        return reservationService.create(body.get("bookId"), body.get("studentRegNo"));
    }

    /**
     * Staff module's "Reserve" / "Join Queue" action — a staff member
     * reserving a book for themselves. Holds a copy immediately if one is
     * free, otherwise joins the queue ahead of student reservations.
     */
    @PostMapping("/self")
    public ReservationDto reserveForSelf(Authentication auth, @RequestBody Map<String, String> body) {
        return reservationService.reserveForStaff(body.get("bookId"), auth.getName());
    }

    /** "Mark Collected" — staff has picked up their held book from the counter. */
    @PostMapping("/{id}/collect")
    public ReservationDto collect(Authentication auth, @PathVariable Long id) {
        return reservationService.collect(id, auth.getName());
    }

    /** "Approve Reservation" button. */
    @PostMapping("/{id}/approve")
    public ReservationDto approve(@PathVariable Long id) {
        return reservationService.approve(id);
    }

    /** "Cancel Reservation" button. */
    @PostMapping("/{id}/cancel")
    public ReservationDto cancel(@PathVariable Long id) {
        return reservationService.cancel(id);
    }

    /** "Notify Student" button. */
    @PostMapping("/{id}/notify")
    public void notifyStudent(@PathVariable Long id) {
        reservationService.notifyStudent(id);
    }
}
