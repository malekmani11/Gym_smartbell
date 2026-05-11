package com.gymapp.service;

import com.gymapp.dto.CoachRatingDTO;
import com.gymapp.dto.RatingRequest;

import java.util.List;

public interface CoachRatingService {

    CoachRatingDTO rateCoach(Long coachId, Long userId, RatingRequest request);

    Double getAverageRating(Long coachId);

    List<CoachRatingDTO> getCoachRatings(Long coachId);
}
