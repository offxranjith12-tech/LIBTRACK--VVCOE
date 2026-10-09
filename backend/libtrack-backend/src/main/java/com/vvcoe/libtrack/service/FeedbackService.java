package com.vvcoe.libtrack.service;

import com.vvcoe.libtrack.model.Feedback;
import com.vvcoe.libtrack.model.Student;
import com.vvcoe.libtrack.repository.FeedbackRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class FeedbackService {

    private final FeedbackRepository feedbackRepository;
    private final StudentService studentService;

    public FeedbackService(FeedbackRepository feedbackRepository, StudentService studentService) {
        this.feedbackRepository = feedbackRepository;
        this.studentService = studentService;
    }

    public Feedback submit(Long studentId, String category, String message) {
        if (message == null || message.isBlank()) {
            throw new IllegalStateException("Feedback message cannot be empty");
        }
        Student student = studentService.getById(studentId);
        Feedback feedback = new Feedback(student, category == null ? "General Feedback" : category, message, LocalDateTime.now());
        return feedbackRepository.save(feedback);
    }

    public List<Feedback> getForStudent(Long studentId) {
        return feedbackRepository.findByStudentIdOrderBySubmittedAtDesc(studentId);
    }
}
