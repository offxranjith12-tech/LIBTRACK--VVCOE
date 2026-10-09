package com.vvce.libtrack.dto;

import com.vvce.libtrack.entity.BookRecommendation;
import com.vvce.libtrack.entity.Feedback;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDateTime;

public class FeedbackDtos {

    public record FeedbackRequest(
            @NotBlank String message,
            Integer rating
    ) {}

    public record FeedbackResponse(
            Long id,
            String message,
            Integer rating,
            LocalDateTime submittedAt
    ) {
        public static FeedbackResponse from(Feedback f) {
            return new FeedbackResponse(f.getId(), f.getMessage(), f.getRating(), f.getSubmittedAt());
        }
    }

    public record RecommendationRequest(
            @NotBlank String title,
            String author,
            String reason
    ) {}

    public record RecommendationResponse(
            Long id,
            String title,
            String author,
            String reason,
            String status,
            LocalDateTime requestedAt
    ) {
        public static RecommendationResponse from(BookRecommendation r) {
            return new RecommendationResponse(r.getId(), r.getTitle(), r.getAuthor(), r.getReason(),
                    r.getStatus().name(), r.getRequestedAt());
        }
    }
}
