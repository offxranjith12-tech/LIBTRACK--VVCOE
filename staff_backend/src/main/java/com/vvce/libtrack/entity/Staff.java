package com.vvce.libtrack.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "staff")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Staff {

    @Id
    @Column(name = "staff_id", nullable = false, unique = true)
    private String staffId;

    @Column(nullable = false)
    private String name;

    private String department;
    private String designation;
    private String email;
    private String phone;

    @Column(length = 500)
    private String address;

    @Column(nullable = false, unique = true)
    private String username;

    /** BCrypt-hashed password. */
    @Column(nullable = false)
    private String password;

    @Column(name = "photo_url", columnDefinition = "LONGTEXT")
    private String photoUrl;
}
