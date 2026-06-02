package com.gymapp.coach.service;

import com.gymapp.coach.dto.CoachRatingDTO;
import com.gymapp.coach.dto.RatingRequest;

import java.util.List;

public interface CoachRatingService {

    CoachRatingDTO rateCoach(Long coachId, Long userId, RatingRequest request);

    Double getAverageRating(Long coachId);

    List<CoachRatingDTO> getCoachRatings(Long coachId);
}
