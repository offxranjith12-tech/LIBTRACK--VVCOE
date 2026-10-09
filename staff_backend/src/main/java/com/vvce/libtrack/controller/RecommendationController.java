package com.vvce.libtrack.controller;

import com.vvce.libtrack.dto.FeedbackDtos;
import com.vvce.libtrack.service.RecommendationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Backs the new Wishlist / Book Recommendations screen (Profile -> Wishlist). */
@RestController
@RequestMapping("/api/recommendations")
@RequiredArgsConstructor
public class RecommendationController {

    private final RecommendationService recommendationService;

    @PostMapping
    public FeedbackDtos.RecommendationResponse submit(Authentication auth, @Valid @RequestBody FeedbackDtos.RecommendationRequest request) {
        return recommendationService.submit(auth.getName(), request);
    }

    @GetMapping
    public List<FeedbackDtos.RecommendationResponse> getAll() {
        return recommendationService.getAll();
    }
}
