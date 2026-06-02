package com.gymapp.service.impl;

import com.gymapp.dto.AbsenceRequestDTO;
import com.gymapp.entity.AbsenceRequest;
import com.gymapp.entity.Coach;
import com.gymapp.entity.enums.AbsenceStatus;
import com.gymapp.entity.enums.AvailabilityStatus;
import com.gymapp.repository.AbsenceRequestRepository;
import com.gymapp.repository.CoachRepository;
import com.gymapp.service.AbsenceRequestService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class AbsenceRequestServiceImpl implements AbsenceRequestService {

    private final AbsenceRequestRepository absenceRepository;
    private final CoachRepository coachRepository;

    @Override
    public AbsenceRequestDTO createRequest(Long coachId, AbsenceRequestDTO dto) {
        log.info("Creating absence request for coach {}", coachId);
        Coach coach = coachRepository.findById(coachId)
                .orElseThrow(() -> new EntityNotFoundException("Coach not found: " + coachId));

        AbsenceRequest request = AbsenceRequest.builder()
                .coach(coach)
                .startDate(dto.getStartDate())
                .endDate(dto.getEndDate())
                .reason(dto.getReason())
                .status(AbsenceStatus.PENDING)
                .build();

        return toDTO(absenceRepository.save(request));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<AbsenceRequestDTO> getRequestsByCoach(Long coachId, Pageable pageable) {
        return absenceRepository.findByCoachId(coachId, pageable).map(this::toDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<AbsenceRequestDTO> getAllRequests(Pageable pageable) {
        return absenceRepository.findAll(pageable).map(this::toDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<AbsenceRequestDTO> getRequestsByStatus(AbsenceStatus status, Pageable pageable) {
        return absenceRepository.findByStatus(status, pageable).map(this::toDTO);
    }

    @Override
    public AbsenceRequestDTO approve(Long id, String adminNote) {
        log.info("Approving absence request {}", id);
        AbsenceRequest request = absenceRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Absence request not found: " + id));

        request.setStatus(AbsenceStatus.APPROVED);
        request.setAdminNote(adminNote);
        request.setReviewedAt(LocalDateTime.now());

        // Set coach to ON_LEAVE
        Coach coach = request.getCoach();
        coach.setAvailabilityStatus(AvailabilityStatus.ON_LEAVE);
        coachRepository.save(coach);

        return toDTO(absenceRepository.save(request));
    }

    @Override
    public AbsenceRequestDTO reject(Long id, String adminNote) {
        log.info("Rejecting absence request {}", id);
        AbsenceRequest request = absenceRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Absence request not found: " + id));

        request.setStatus(AbsenceStatus.REJECTED);
        request.setAdminNote(adminNote);
        request.setReviewedAt(LocalDateTime.now());

        return toDTO(absenceRepository.save(request));
    }

    private AbsenceRequestDTO toDTO(AbsenceRequest r) {
        Coach c = r.getCoach();
        return AbsenceRequestDTO.builder()
                .id(r.getId())
                .coachId(c.getId())
                .coachFirstName(c.getFirstName())
                .coachLastName(c.getLastName())
                .coachEmail(c.getEmail())
                .startDate(r.getStartDate())
                .endDate(r.getEndDate())
                .reason(r.getReason())
                .status(r.getStatus())
                .adminNote(r.getAdminNote())
                .createdAt(r.getCreatedAt())
                .reviewedAt(r.getReviewedAt())
                .build();
    }
}
