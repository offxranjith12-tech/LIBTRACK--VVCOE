package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.FeedbackDtos;
import com.vvce.libtrack.entity.BookRecommendation;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.BookRecommendationRepository;
import com.vvce.libtrack.repository.StaffRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RecommendationService {

    private final BookRecommendationRepository recommendationRepository;
    private final StaffRepository staffRepository;

    /** Powers the Wishlist screen's "Recommend a Book" form. */
    public FeedbackDtos.RecommendationResponse submit(String username, FeedbackDtos.RecommendationRequest request) {
        String staffId = staffRepository.findByUsername(username)
                .map(com.vvce.libtrack.entity.Staff::getStaffId)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + username));

        BookRecommendation rec = BookRecommendation.builder()
                .staffId(staffId)
                .title(request.title())
                .author(request.author())
                .reason(request.reason())
                .requestedAt(LocalDateTime.now())
                .status(BookRecommendation.Status.PENDING)
                .build();
        recommendationRepository.save(rec);
        return FeedbackDtos.RecommendationResponse.from(rec);
    }

    /** Powers the Wishlist screen's list. */
    public List<FeedbackDtos.RecommendationResponse> getAll() {
        return recommendationRepository.findAllByOrderByRequestedAtDesc()
                .stream().map(FeedbackDtos.RecommendationResponse::from).toList();
    }
}
