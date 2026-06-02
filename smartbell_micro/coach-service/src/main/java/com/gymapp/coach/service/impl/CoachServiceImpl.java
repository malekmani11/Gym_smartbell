package com.gymapp.coach.service.impl;

import com.gymapp.coach.dto.CoachDTO;
import com.gymapp.coach.entity.Coach;
import com.gymapp.coach.entity.Role;
import com.gymapp.coach.entity.enums.AvailabilityStatus;
import com.gymapp.coach.mapper.EntityMapper;
import com.gymapp.coach.repository.CoachRepository;
import com.gymapp.coach.repository.UserRepository;
import com.gymapp.coach.service.CoachService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class CoachServiceImpl implements CoachService {

    private final CoachRepository coachRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EntityMapper mapper;

    @Override
    public CoachDTO createCoach(Long coachId, CoachDTO dto) {
        log.info("Updating coach profile: {}", coachId);
        Coach coach = coachRepository.findById(coachId)
                .orElseThrow(() -> new EntityNotFoundException("Coach not found with id: " + coachId));

        if (dto.getSpecialization() != null) coach.setSpecialization(dto.getSpecialization());
        if (dto.getBio() != null)            coach.setBio(dto.getBio());
        if (dto.getCertification() != null)  coach.setCertification(dto.getCertification());
        if (dto.getHireDate() != null)       coach.setHireDate(dto.getHireDate());

        return mapper.toCoachDTO(coachRepository.save(coach));
    }

    @Override
    public CoachDTO createCoachDirect(CoachDTO dto) {
        log.info("Creating coach directly: {}", dto.getEmail());

        if (userRepository.existsByEmail(dto.getEmail())) {
            throw new IllegalStateException("Email already exists: " + dto.getEmail());
        }

        Coach coach = Coach.builder()
                .firstName(dto.getFirstName())
                .lastName(dto.getLastName())
                .email(dto.getEmail())
                .password(passwordEncoder.encode("Gym@123456"))
                .phone(dto.getPhone())
                .profileImageUrl(dto.getProfileImageUrl())
                .role(Role.ROLE_COACH)
                .enabled(true)
                .specialization(dto.getSpecialization())
                .bio(dto.getBio())
                .certification(dto.getCertification())
                .hireDate(dto.getHireDate() != null ? dto.getHireDate() : LocalDate.now())
                .availabilityStatus(AvailabilityStatus.AVAILABLE)
                .build();

        return mapper.toCoachDTO(coachRepository.save(coach));
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
        return getCoachById(userId);
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

        if (dto.getFirstName() != null) coach.setFirstName(dto.getFirstName());
        if (dto.getLastName() != null)  coach.setLastName(dto.getLastName());
        if (dto.getEmail() != null)     coach.setEmail(dto.getEmail());
        if (dto.getPhone() != null)     coach.setPhone(dto.getPhone());
        if (dto.getProfileImageUrl() != null) coach.setProfileImageUrl(dto.getProfileImageUrl());
        if (dto.getSpecialization() != null)    coach.setSpecialization(dto.getSpecialization());
        if (dto.getBio() != null)               coach.setBio(dto.getBio());
        if (dto.getCertification() != null)     coach.setCertification(dto.getCertification());
        if (dto.getAvailabilityStatus() != null) coach.setAvailabilityStatus(dto.getAvailabilityStatus());
        if (dto.getHireDate() != null)          coach.setHireDate(dto.getHireDate());

        return mapper.toCoachDTO(coachRepository.save(coach));
    }

    @Override
    public void declareAbsence(Long coachId, CoachDTO dto) {
        Coach coach = coachRepository.findById(coachId)
                .orElseThrow(() -> new EntityNotFoundException("Coach not found with id: " + coachId));
        if (dto.getAvailabilityStatus() != null) coach.setAvailabilityStatus(dto.getAvailabilityStatus());
        if (dto.getAbsenceStart()  != null) coach.setAbsenceStart(dto.getAbsenceStart());
        if (dto.getAbsenceEnd()    != null) coach.setAbsenceEnd(dto.getAbsenceEnd());
        if (dto.getAbsenceReason() != null) coach.setAbsenceReason(dto.getAbsenceReason());
        coachRepository.save(coach);
    }

    @Override
    public void deleteCoach(Long id) {
        log.warn("Deleting coach: {}", id);
        Coach coach = coachRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Coach not found with id: " + id));
        coachRepository.delete(coach);
    }
}
