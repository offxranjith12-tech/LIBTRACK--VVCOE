package com.vvcoe.libtrack.repository;

import com.vvcoe.libtrack.model.Feedback;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FeedbackRepository extends JpaRepository<Feedback, Long> {
    List<Feedback> findByStudentIdOrderBySubmittedAtDesc(Long studentId);
}
