package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.FeedbackDtos;
import com.vvce.libtrack.service.FeedbackService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Backs the new Feedback screen (Profile -> Feedback). */
@RestController
@RequestMapping("/api/feedback")
@RequiredArgsConstructor
public class FeedbackController {

    private final FeedbackService feedbackService;

    @PostMapping
    public FeedbackDtos.FeedbackResponse submit(Authentication auth, @Valid @RequestBody FeedbackDtos.FeedbackRequest request) {
        return feedbackService.submit(auth.getName(), request);
    }

    @GetMapping
    public List<FeedbackDtos.FeedbackResponse> getAll() {
        return feedbackService.getAll();
    }
}
