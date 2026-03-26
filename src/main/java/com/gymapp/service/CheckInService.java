package com.gymapp.service;

import com.gymapp.dto.CheckInDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface CheckInService {

    CheckInDTO checkIn(Long memberId, Long receptionistId);

    CheckInDTO checkOut(Long memberId);

    Page<CheckInDTO> getCheckInsByMember(Long memberId, Pageable pageable);

    CheckInDTO getActiveCheckIn(Long memberId);
}
