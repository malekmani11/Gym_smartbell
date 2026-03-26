package com.gymapp.service;

import com.gymapp.dto.CoachDTO;
import com.gymapp.entity.enums.AvailabilityStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface CoachService {

    CoachDTO createCoach(Long userId, CoachDTO dto);

    CoachDTO getCoachById(Long id);

    CoachDTO getCoachByUserId(Long userId);

    Page<CoachDTO> getAllCoaches(Pageable pageable);

    Page<CoachDTO> getCoachesByStatus(AvailabilityStatus status, Pageable pageable);

    CoachDTO updateCoach(Long id, CoachDTO dto);

    void deleteCoach(Long id);
}
