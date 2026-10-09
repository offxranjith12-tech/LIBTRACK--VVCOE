package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Singleton settings row (id is always 1). Holds the library's operating
 * hours and borrowing/reservation rules, editable by the Admin and readable
 * by Students/Staff so they always see the current timing and limits.
 */
@Entity
@Table(name = "library_settings")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LibrarySettings {

    @Id
    private Long id;

    @Column(name = "opening_time", length = 10)
    @Builder.Default
    private String openingTime = "08:30";

    @Column(name = "closing_time", length = 10)
    @Builder.Default
    private String closingTime = "18:00";

    @Column(name = "working_days", length = 100)
    @Builder.Default
    private String workingDays = "Mon-Sat";

    @Column(name = "max_borrow_limit_student")
    @Builder.Default
    private Integer maxBorrowLimitStudent = 3;

    @Column(name = "max_borrow_limit_staff")
    @Builder.Default
    private Integer maxBorrowLimitStaff = 5;

    @Column(name = "max_reservation_limit")
    @Builder.Default
    private Integer maxReservationLimit = 2;

    @Column(name = "borrow_duration_days")
    @Builder.Default
    private Integer borrowDurationDays = 14;

    @Column(name = "fine_per_day")
    @Builder.Default
    private Double finePerDay = 2.0;

    @Column(name = "extension_days_allowed")
    @Builder.Default
    private Integer extensionDaysAllowed = 7;

    @Column(name = "announcement", length = 500)
    private String announcement;
}
