package com.vvce.libtrack.dto;

import com.vvce.libtrack.entity.Reservation;

import java.time.LocalDateTime;

public record ReservationDto(
        Long id,
        BookDto book,
        StudentDto student,
        LocalDateTime reservedOn,
        Integer queuePosition,
        String status,
        boolean isAvailable,
        boolean isStaffReservation
) {
    public static ReservationDto from(Reservation r) {
        return new ReservationDto(
                r.getId(), BookDto.from(r.getBook()),
                r.getStudent() != null ? StudentDto.from(r.getStudent()) : null,
                r.getReservedOn(), r.getQueuePosition(), r.getStatus().name(),
                r.getStatus() == Reservation.Status.AVAILABLE,
                r.isStaffReservation()
        );
    }
}
