package com.vvcoe.libtrack.controller;

import com.vvcoe.libtrack.model.Feedback;
import com.vvcoe.libtrack.service.FeedbackService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class FeedbackController {

    private final FeedbackService feedbackService;

    public FeedbackController(FeedbackService feedbackService) {
        this.feedbackService = feedbackService;
    }

    @PostMapping("/feedback")
    public ResponseEntity<Feedback> submit(@RequestBody Map<String, String> body) {
        Long studentId = Long.valueOf(body.get("studentId"));
        Feedback feedback = feedbackService.submit(studentId, body.get("category"), body.get("message"));
        return ResponseEntity.ok(feedback);
    }

    @GetMapping("/students/{studentId}/feedback")
    public ResponseEntity<List<Feedback>> getForStudent(@PathVariable Long studentId) {
        return ResponseEntity.ok(feedbackService.getForStudent(studentId));
    }
}
