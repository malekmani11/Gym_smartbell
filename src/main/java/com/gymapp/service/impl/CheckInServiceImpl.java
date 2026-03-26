package com.gymapp.service.impl;

import com.gymapp.dto.CheckInDTO;
import com.gymapp.entity.CheckIn;
import com.gymapp.entity.Member;
import com.gymapp.entity.User;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.CheckInRepository;
import com.gymapp.repository.MemberRepository;
import com.gymapp.repository.UserRepository;
import com.gymapp.service.CheckInService;
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
public class CheckInServiceImpl implements CheckInService {

    private final CheckInRepository checkInRepository;
    private final MemberRepository memberRepository;
    private final UserRepository userRepository;
    private final EntityMapper mapper;

    @Override
    public CheckInDTO checkIn(Long memberId, Long receptionistId) {
        log.info("Member {} checking in, processed by receptionist {}", memberId, receptionistId);

        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("Member not found"));
        User receptionist = userRepository.findById(receptionistId)
                .orElseThrow(() -> new EntityNotFoundException("Receptionist not found"));

        // Check if already checked in
        checkInRepository.findTopByMemberIdAndCheckOutTimeIsNullOrderByCheckInTimeDesc(memberId)
                .ifPresent(existing -> {
                    throw new IllegalStateException("Member is already checked in");
                });

        CheckIn checkIn = CheckIn.builder()
                .member(member)
                .checkInTime(LocalDateTime.now())
                .checkedBy(receptionist)
                .build();

        return mapper.toCheckInDTO(checkInRepository.save(checkIn));
    }

    @Override
    public CheckInDTO checkOut(Long memberId) {
        log.info("Member {} checking out", memberId);
        CheckIn checkIn = checkInRepository
                .findTopByMemberIdAndCheckOutTimeIsNullOrderByCheckInTimeDesc(memberId)
                .orElseThrow(() -> new IllegalStateException("No active check-in found for member"));

        checkIn.setCheckOutTime(LocalDateTime.now());
        return mapper.toCheckInDTO(checkInRepository.save(checkIn));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<CheckInDTO> getCheckInsByMember(Long memberId, Pageable pageable) {
        return checkInRepository.findByMemberId(memberId, pageable).map(mapper::toCheckInDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public CheckInDTO getActiveCheckIn(Long memberId) {
        CheckIn checkIn = checkInRepository
                .findTopByMemberIdAndCheckOutTimeIsNullOrderByCheckInTimeDesc(memberId)
                .orElseThrow(() -> new EntityNotFoundException("No active check-in found"));
        return mapper.toCheckInDTO(checkIn);
    }
}
