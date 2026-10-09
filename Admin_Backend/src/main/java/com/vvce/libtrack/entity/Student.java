package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "students", indexes = {
        @Index(name = "idx_student_regno", columnList = "registerNumber"),
        @Index(name = "idx_student_dept", columnList = "department")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String registerNumber;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(length = 50)
    private String department;

    private Integer semester;

    @Column(nullable = false, unique = true, length = 200)
    private String email;

    @Column(length = 20)
    private String phone;

    /** BCrypt-hashed password. Students log in with their register number + this password. */
    @Column(length = 255)
    private String password;

    @Column(name = "borrowed_books_count")
    @Builder.Default
    private Integer borrowedBooksCount = 0;

    @Column(name = "borrow_limit")
    @Builder.Default
    private Integer borrowLimit = 3;

    @Column(length = 20)
    @Builder.Default
    private String status = "ACTIVE";

    @Column(name = "joined_on")
    private LocalDateTime joinedOn;

    /** Relative URL (e.g. /uploads/avatars/xyz.jpg) served statically by this backend. */
    @Column(name = "avatar_url", length = 500)
    private String avatarUrl;

    @PrePersist
    public void prePersist() {
        if (joinedOn == null) joinedOn = LocalDateTime.now();
    }
}
