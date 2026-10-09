package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface StudentRepository extends JpaRepository<Student, String> {

    Optional<Student> findByRegNo(String regNo);

    @Query("SELECT s FROM Student s WHERE LOWER(s.name) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(s.regNo) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Student> search(@Param("query") String query);
}
