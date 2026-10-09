package com.vvce.libtrack.service;

import com.vvce.libtrack.dto.FeedbackDtos;
import com.vvce.libtrack.entity.Feedback;
import com.vvce.libtrack.exception.ResourceNotFoundException;
import com.vvce.libtrack.repository.FeedbackRepository;
import com.vvce.libtrack.repository.StaffRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class FeedbackService {

    private final FeedbackRepository feedbackRepository;
    private final StaffRepository staffRepository;

    /** Powers the Feedback screen's submit form. Accepts the authenticated
     *  username and resolves it to the staffId that submitted the feedback. */
    public FeedbackDtos.FeedbackResponse submit(String username, FeedbackDtos.FeedbackRequest request) {
        String staffId = staffRepository.findByUsername(username)
                .map(com.vvce.libtrack.entity.Staff::getStaffId)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + username));

        Feedback feedback = Feedback.builder()
                .staffId(staffId)
                .message(request.message())
                .rating(request.rating())
                .submittedAt(LocalDateTime.now())
                .build();
        feedbackRepository.save(feedback);
        return FeedbackDtos.FeedbackResponse.from(feedback);
    }

    /** Powers the Feedback screen's history list. */
    public List<FeedbackDtos.FeedbackResponse> getAll() {
        return feedbackRepository.findAllByOrderBySubmittedAtDesc()
                .stream().map(FeedbackDtos.FeedbackResponse::from).toList();
    }
}
