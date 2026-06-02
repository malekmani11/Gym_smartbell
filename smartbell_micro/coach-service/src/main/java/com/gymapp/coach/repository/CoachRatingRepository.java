package com.gymapp.coach.repository;

import com.gymapp.coach.entity.CoachRating;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CoachRatingRepository extends JpaRepository<CoachRating, Long> {

    List<CoachRating> findByCoachId(Long coachId);

    @Query("SELECT r FROM CoachRating r JOIN FETCH r.member WHERE r.coach.id = :coachId")
    List<CoachRating> findByCoachIdWithMember(@Param("coachId") Long coachId);

    Optional<CoachRating> findByCoachIdAndMemberId(Long coachId, Long memberId);

    @Query("SELECT AVG(r.rating) FROM CoachRating r WHERE r.coach.id = :coachId")
    Optional<Double> calculateAverageRating(@Param("coachId") Long coachId);
}
