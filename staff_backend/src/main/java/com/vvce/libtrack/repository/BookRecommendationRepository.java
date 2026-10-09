package com.vvce.libtrack.repository;

import com.vvce.libtrack.entity.BookRecommendation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BookRecommendationRepository extends JpaRepository<BookRecommendation, Long> {
    List<BookRecommendation> findAllByOrderByRequestedAtDesc();
}
