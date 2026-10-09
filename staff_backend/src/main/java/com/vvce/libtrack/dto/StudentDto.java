package com.vvce.libtrack.dto;

import com.vvce.libtrack.entity.Student;

import java.util.List;

public record StudentDto(
        String regNo,
        String name,
        String department,
        Integer year,
        Integer borrowLimit,
        Integer currentBorrowed,
        Double fineDue
) {
    public static StudentDto from(Student s) {
        return new StudentDto(s.getRegNo(), s.getName(), s.getDepartment(), s.getYear(),
                s.getBorrowLimit(), s.getCurrentBorrowed(), s.getFineDue());
    }

    /** Full detail payload for the Student Information screen. */
    public record StudentDetails(
            StudentDto student,
            List<TransactionDto> borrowedBooks,
            List<ReservationDto> reservationHistory
    ) {}
}
