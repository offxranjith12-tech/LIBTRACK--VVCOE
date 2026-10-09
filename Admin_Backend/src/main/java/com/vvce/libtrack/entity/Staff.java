package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "staff", indexes = {
        @Index(name = "idx_staff_id", columnList = "staffId"),
        @Index(name = "idx_staff_dept", columnList = "department")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Staff {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String staffId;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(length = 50)
    private String department;

    @Column(length = 100)
    private String designation;

    @Column(nullable = false, unique = true, length = 200)
    private String email;

    @Column(length = 20)
    private String phone;

    /** BCrypt-hashed password. Staff/Librarians log in with their staffId + this password. */
    @Column(length = 255)
    private String password;

    /** STAFF (teaching faculty) or LIBRARIAN (library desk staff — full librarian login). */
    @Column(length = 20)
    @Builder.Default
    private String role = "STAFF";

    @Column(name = "borrowed_books_count")
    @Builder.Default
    private Integer borrowedBooksCount = 0;

    @Column(name = "borrow_limit")
    @Builder.Default
    private Integer borrowLimit = 5;

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
