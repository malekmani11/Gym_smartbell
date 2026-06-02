package com.gymapp.service.impl;

import com.gymapp.dto.CoachDTO;
import com.gymapp.dto.CoachStatsDto;
import com.gymapp.entity.Coach;
import com.gymapp.entity.Role;
import com.gymapp.entity.enums.AvailabilityStatus;
import com.gymapp.entity.enums.ReservationStatus;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.CoachRepository;
import com.gymapp.repository.CourseRepository;
import com.gymapp.repository.CourseReservationRepository;
import com.gymapp.repository.UserRepository;
import com.gymapp.service.CoachService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class CoachServiceImpl implements CoachService {

    private final CoachRepository coachRepository;
    private final UserRepository userRepository;
    private final CourseRepository courseRepository;
    private final CourseReservationRepository reservationRepository;
    private final PasswordEncoder passwordEncoder;
    private final EntityMapper mapper;
    private final com.gymapp.repository.RefreshTokenRepository refreshTokenRepository;
    private final com.gymapp.service.EmailService emailService;

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

        Coach saved = coachRepository.save(coach);
        emailService.sendWelcomeEmail(saved.getEmail(), saved.getFirstName());
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

        // Basic user fields
        if (dto.getFirstName() != null) coach.setFirstName(dto.getFirstName());
        if (dto.getLastName() != null)  coach.setLastName(dto.getLastName());
        if (dto.getEmail() != null)     coach.setEmail(dto.getEmail());
        if (dto.getPhone() != null)     coach.setPhone(dto.getPhone());
        if (dto.getProfileImageUrl() != null) coach.setProfileImageUrl(dto.getProfileImageUrl());

        // Coach specific fields
        if (dto.getSpecialization() != null)    coach.setSpecialization(dto.getSpecialization());
        if (dto.getBio() != null)               coach.setBio(dto.getBio());
        if (dto.getCertification() != null)     coach.setCertification(dto.getCertification());
        if (dto.getAvailabilityStatus() != null) coach.setAvailabilityStatus(dto.getAvailabilityStatus());
        if (dto.getHireDate() != null)          coach.setHireDate(dto.getHireDate());

        return mapper.toCoachDTO(coachRepository.save(coach));
    }

    @Override
    @Transactional(readOnly = true)
    public CoachStatsDto getCoachStats(Long coachId) {
        coachRepository.findById(coachId)
                .orElseThrow(() -> new EntityNotFoundException("Coach not found: " + coachId));

        List<com.gymapp.entity.Course> courses = courseRepository.findByCoachId(coachId);
        int totalCourses = courses.size();

        int totalEnrollments = 0;
        int totalCapacity = 0;
        java.util.Set<Long> memberIds = new java.util.HashSet<>();

        for (com.gymapp.entity.Course course : courses) {
            long confirmed = reservationRepository.countByCourseIdAndStatus(course.getId(), ReservationStatus.CONFIRMED);
            totalEnrollments += (int) confirmed;
            totalCapacity += course.getMaxParticipants();
            course.getReservations().stream()
                    .filter(r -> r.getStatus() == ReservationStatus.CONFIRMED)
                    .forEach(r -> memberIds.add(r.getMember().getId()));
        }

        double avgOccupancyRate = totalCapacity > 0
                ? Math.round((totalEnrollments * 100.0 / totalCapacity) * 10.0) / 10.0
                : 0.0;

        return CoachStatsDto.builder()
                .totalCourses(totalCourses)
                .totalEnrollments(totalEnrollments)
                .activeMembers(memberIds.size())
                .avgOccupancyRate(avgOccupancyRate)
                .build();
    }

    @Override
    public void deleteCoach(Long id) {
        log.warn("Deleting coach: {}", id);
        Coach coach = coachRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Coach not found with id: " + id));
        refreshTokenRepository.deleteByUser(coach);
        coachRepository.delete(coach);
    }
}
