package com.gymapp.coach.controller;

import com.gymapp.coach.dto.CoachRatingDTO;
import com.gymapp.coach.dto.RatingRequest;
import com.gymapp.coach.service.CoachRatingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/coaches/{coachId}/ratings")
@RequiredArgsConstructor
public class CoachRatingController {

    private final CoachRatingService ratingService;

    @PostMapping
    public ResponseEntity<CoachRatingDTO> rateCoach(
            @PathVariable Long coachId,
            @Valid @RequestBody RatingRequest request,
            @RequestHeader(value = "X-User-Id", required = false) Long userId) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ratingService.rateCoach(coachId, userId, request));
    }

    @GetMapping
    public ResponseEntity<List<CoachRatingDTO>> getCoachRatings(@PathVariable Long coachId) {
        return ResponseEntity.ok(ratingService.getCoachRatings(coachId));
    }

    @GetMapping("/average")
    public ResponseEntity<Double> getAverageRating(@PathVariable Long coachId) {
        return ResponseEntity.ok(ratingService.getAverageRating(coachId));
    }
}
