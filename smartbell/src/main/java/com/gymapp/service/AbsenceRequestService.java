package com.gymapp.service;

import com.gymapp.dto.AbsenceRequestDTO;
import com.gymapp.entity.enums.AbsenceStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface AbsenceRequestService {

    AbsenceRequestDTO createRequest(Long coachId, AbsenceRequestDTO dto);

    Page<AbsenceRequestDTO> getRequestsByCoach(Long coachId, Pageable pageable);

    Page<AbsenceRequestDTO> getAllRequests(Pageable pageable);

    Page<AbsenceRequestDTO> getRequestsByStatus(AbsenceStatus status, Pageable pageable);

    AbsenceRequestDTO approve(Long id, String adminNote);

    AbsenceRequestDTO reject(Long id, String adminNote);
}
