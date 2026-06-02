package com.gymapp.service;

import com.gymapp.dto.CheckInDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface CheckInService {
    CheckInDTO checkIn(Long memberId);
    CheckInDTO checkOut(Long memberId);
    List<CheckInDTO> getTodayCheckIns();
    List<CheckInDTO> getCheckInsByMember(Long memberId);
    Page<CheckInDTO> getAll(Pageable pageable);
    long countToday();
    long countThisWeek();
    long countThisMonth();
}
