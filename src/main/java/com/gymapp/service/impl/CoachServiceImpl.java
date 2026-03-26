package com.gymapp.service.impl;

import com.gymapp.dto.CoachDTO;
import com.gymapp.entity.Coach;
import com.gymapp.entity.User;
import com.gymapp.entity.enums.AvailabilityStatus;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.CoachRepository;
import com.gymapp.repository.UserRepository;
import com.gymapp.service.CoachService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class CoachServiceImpl implements CoachService {

    private final CoachRepository coachRepository;
    private final UserRepository userRepository;
    private final EntityMapper mapper;

    @Override
    public CoachDTO createCoach(Long userId, CoachDTO dto) {
        log.info("Creating coach profile for user: {}", userId);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found with id: " + userId));

        if (coachRepository.existsByUserId(userId)) {
            throw new IllegalStateException("Coach profile already exists for user: " + userId);
        }

        Coach coach = Coach.builder()
                .user(user)
                .specialization(dto.getSpecialization())
                .bio(dto.getBio())
                .certification(dto.getCertification())
                .hireDate(dto.getHireDate())
                .availabilityStatus(AvailabilityStatus.AVAILABLE)
                .build();

        Coach saved = coachRepository.save(coach);
        log.info("Coach profile created: {}", saved.getId());
        return mapper.toCoachDTO(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public CoachDTO getCoachById(Long id) {
        Coach coach = coachRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Coach not found with id: " + id));
        return mapper.toCoachDTO(coach);
    }

    @Override
    @Transactional(readOnly = true)
    public CoachDTO getCoachByUserId(Long userId) {
        Coach coach = coachRepository.findByUserId(userId)
                .orElseThrow(() -> new EntityNotFoundException("Coach not found for user: " + userId));
        return mapper.toCoachDTO(coach);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<CoachDTO> getAllCoaches(Pageable pageable) {
        return coachRepository.findAll(pageable).map(mapper::toCoachDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<CoachDTO> getCoachesByStatus(AvailabilityStatus status, Pageable pageable) {
        return coachRepository.findByAvailabilityStatus(status, pageable).map(mapper::toCoachDTO);
    }

    @Override
    public CoachDTO updateCoach(Long id, CoachDTO dto) {
        log.info("Updating coach: {}", id);
        Coach coach = coachRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Coach not found with id: " + id));

        if (dto.getSpecialization() != null)
            coach.setSpecialization(dto.getSpecialization());
        if (dto.getBio() != null)
            coach.setBio(dto.getBio());
        if (dto.getCertification() != null)
            coach.setCertification(dto.getCertification());
        if (dto.getAvailabilityStatus() != null)
            coach.setAvailabilityStatus(dto.getAvailabilityStatus());

        return mapper.toCoachDTO(coachRepository.save(coach));
    }

    @Override
    public void deleteCoach(Long id) {
        log.warn("Deleting coach: {}", id);
        if (!coachRepository.existsById(id)) {
            throw new EntityNotFoundException("Coach not found with id: " + id);
        }
        coachRepository.deleteById(id);
    }
}
