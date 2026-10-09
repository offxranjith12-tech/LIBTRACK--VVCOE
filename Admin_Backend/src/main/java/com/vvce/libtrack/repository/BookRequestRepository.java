package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.BookRequest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BookRequestRepository extends JpaRepository<BookRequest, Long> {

    List<BookRequest> findByStatusOrderByRequestedAtDesc(String status);

    List<BookRequest> findByStudentIdOrderByRequestedAtDesc(String studentId);

    List<BookRequest> findAllByOrderByRequestedAtDesc();
}
