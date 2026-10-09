package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByRegisterNumber(String registerNumber);
    Optional<Student> findByEmail(String email);
    long countByStatus(String status);
}
