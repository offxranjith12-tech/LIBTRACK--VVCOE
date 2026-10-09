package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "student")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Student {

    @Id
    @Column(name = "reg_no", nullable = false, unique = true)
    private String regNo;

    @Column(nullable = false)
    private String name;

    private String department;
    private Integer year;

    @Column(name = "borrow_limit")
    private Integer borrowLimit;

    @Column(name = "current_borrowed")
    private Integer currentBorrowed;

    @Column(name = "fine_due")
    private Double fineDue;
}
