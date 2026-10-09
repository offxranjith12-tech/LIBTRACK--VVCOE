package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.Staff;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StaffRepository extends JpaRepository<Staff, String> {
    Optional<Staff> findByUsername(String username);
}
