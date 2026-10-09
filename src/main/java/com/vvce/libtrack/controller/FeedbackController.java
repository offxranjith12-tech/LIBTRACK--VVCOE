package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.ApiResponse;
import com.vvce.libtrack.dto.FeedbackRequest;
import com.vvce.libtrack.entity.Feedback;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.FeedbackRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Students and Staff submit feedback here; the Admin reviews and resolves it
 * from the Settings screen. Listing/resolving is restricted to Admin/Librarian
 * in SecurityConfig.
 */
@RestController
@RequestMapping("/api/v1/feedback")
@RequiredArgsConstructor
public class FeedbackController {

    private final FeedbackRepository feedbackRepository;

    @PostMapping
    public ApiResponse<Feedback> submit(@Valid @RequestBody FeedbackRequest request) {
        Feedback feedback = Feedback.builder()
                .senderId(request.getSenderId())
                .senderName(request.getSenderName())
                .senderType(request.getSenderType().toUpperCase())
                .message(request.getMessage())
                .status("OPEN")
                .build();
        return ApiResponse.ok("Feedback submitted", feedbackRepository.save(feedback));
    }

    @GetMapping
    public ApiResponse<List<Feedback>> getAll() {
        return ApiResponse.ok(feedbackRepository.findAllByOrderByCreatedAtDesc());
    }

    @PatchMapping("/{id}/resolve")
    public ApiResponse<Feedback> resolve(@PathVariable Long id, @RequestBody(required = false) String adminResponse) {
        Feedback feedback = feedbackRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Feedback not found: " + id));
        feedback.setStatus("RESOLVED");
        if (adminResponse != null && !adminResponse.isBlank()) {
            feedback.setAdminResponse(adminResponse);
        }
        return ApiResponse.ok("Feedback marked as resolved", feedbackRepository.save(feedback));
    }
}
