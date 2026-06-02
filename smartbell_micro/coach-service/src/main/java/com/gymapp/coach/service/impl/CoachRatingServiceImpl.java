package com.gymapp.coach.service.impl;

import com.gymapp.coach.dto.CoachRatingDTO;
import com.gymapp.coach.dto.RatingRequest;
import com.gymapp.coach.entity.Coach;
import com.gymapp.coach.entity.CoachRating;
import com.gymapp.coach.entity.User;
import com.gymapp.coach.exception.BadRequestException;
import com.gymapp.coach.exception.ResourceNotFoundException;
import com.gymapp.coach.repository.CoachRatingRepository;
import com.gymapp.coach.repository.CoachRepository;
import com.gymapp.coach.repository.UserRepository;
import com.gymapp.coach.service.CoachRatingService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CoachRatingServiceImpl implements CoachRatingService {

    private final CoachRatingRepository ratingRepository;
    private final CoachRepository coachRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional
    public CoachRatingDTO rateCoach(Long coachId, Long userId, RatingRequest request) {
        if (request.getRating() == null || request.getRating() < 1 || request.getRating() > 5) {
            throw new BadRequestException("Note invalide : la note doit être entre 1 et 5");
        }

        Coach coach = coachRepository.findById(coachId)
                .orElseThrow(() -> new ResourceNotFoundException("Coach introuvable avec l'id : " + coachId));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable avec l'id : " + userId));

        if (ratingRepository.findByCoachIdAndMemberId(coachId, userId).isPresent()) {
            throw new BadRequestException("Vous avez déjà noté ce coach");
        }

        CoachRating rating = CoachRating.builder()
                .coach(coach)
                .member(user)
                .rating(request.getRating())
                .comment(request.getComment())
                .build();

        CoachRating saved = ratingRepository.save(rating);
        updateCoachRatingAvg(coachId, coach);

        return toDTO(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public Double getAverageRating(Long coachId) {
        if (!coachRepository.existsById(coachId)) {
            throw new ResourceNotFoundException("Coach introuvable avec l'id : " + coachId);
        }
        return ratingRepository.calculateAverageRating(coachId).orElse(0.0);
    }

    @Override
    @Transactional(readOnly = true)
    public List<CoachRatingDTO> getCoachRatings(Long coachId) {
        if (!coachRepository.existsById(coachId)) {
            throw new ResourceNotFoundException("Coach introuvable avec l'id : " + coachId);
        }
        return ratingRepository.findByCoachIdWithMember(coachId).stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    private void updateCoachRatingAvg(Long coachId, Coach coach) {
        Double avg = ratingRepository.calculateAverageRating(coachId).orElse(0.0);
        coach.setRatingAvg(Math.round(avg * 10.0) / 10.0);
        coachRepository.save(coach);
    }

    private CoachRatingDTO toDTO(CoachRating r) {
        return CoachRatingDTO.builder()
                .id(r.getId())
                .coachId(r.getCoach().getId())
                .memberId(r.getMember().getId())
                .memberName(r.getMember().getFirstName() + " " + r.getMember().getLastName())
                .rating(r.getRating())
                .comment(r.getComment())
                .createdAt(r.getCreatedAt())
                .build();
    }
}
