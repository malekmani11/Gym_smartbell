package com.gymapp.service.impl;

import com.gymapp.dto.CheckInDTO;
import com.gymapp.entity.CheckIn;
import com.gymapp.entity.Member;
import com.gymapp.repository.CheckInRepository;
import com.gymapp.repository.MemberRepository;
import com.gymapp.service.CheckInService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CheckInServiceImpl implements CheckInService {

    private final CheckInRepository checkInRepository;
    private final MemberRepository memberRepository;

    @Override
    @Transactional
    public CheckInDTO checkIn(Long memberId) {
        Member member = findMember(memberId);
        CheckIn checkIn = CheckIn.builder()
                .member(member)
                .build();
        checkInRepository.save(checkIn);
        log.info("CheckIn recorded for member {}", memberId);
        return toDTO(checkIn);
    }

    @Override
    @Transactional
    public CheckInDTO checkOut(Long memberId) {
        CheckIn checkIn = checkInRepository
                .findFirstByMember_IdAndCheckOutTimeIsNullOrderByCheckInTimeDesc(memberId)
                .orElseThrow(() -> new IllegalStateException("Aucun check-in actif pour le membre " + memberId));
        checkIn.setCheckOutTime(LocalDateTime.now());
        checkInRepository.save(checkIn);
        log.info("CheckOut recorded for member {}", memberId);
        return toDTO(checkIn);
    }

    @Override
    public List<CheckInDTO> getTodayCheckIns() {
        LocalDateTime start = LocalDate.now().atStartOfDay();
        LocalDateTime end = LocalDate.now().atTime(LocalTime.MAX);
        return checkInRepository.findByCheckInTimeBetweenOrderByCheckInTimeDesc(start, end)
                .stream().map(this::toDTO).toList();
    }

    @Override
    public List<CheckInDTO> getCheckInsByMember(Long memberId) {
        return checkInRepository.findByMember_IdOrderByCheckInTimeDesc(memberId)
                .stream().map(this::toDTO).toList();
    }

    @Override
    public Page<CheckInDTO> getAll(Pageable pageable) {
        return checkInRepository.findAllByOrderByCheckInTimeDesc(pageable).map(this::toDTO);
    }

    @Override
    public long countToday() {
        LocalDateTime start = LocalDate.now().atStartOfDay();
        LocalDateTime end = LocalDate.now().atTime(LocalTime.MAX);
        return checkInRepository.countByCheckInTimeBetween(start, end);
    }

    @Override
    public long countThisWeek() {
        LocalDate now = LocalDate.now();
        LocalDate startOfWeek = now.with(DayOfWeek.MONDAY);
        return checkInRepository.countByCheckInTimeBetween(startOfWeek.atStartOfDay(), now.atTime(LocalTime.MAX));
    }

    @Override
    public long countThisMonth() {
        LocalDateTime start = LocalDate.now().withDayOfMonth(1).atStartOfDay();
        LocalDateTime end = LocalDate.now().atTime(LocalTime.MAX);
        return checkInRepository.countByCheckInTimeBetween(start, end);
    }

    private Member findMember(Long memberId) {
        return memberRepository.findById(memberId)
                .orElseThrow(() -> new IllegalArgumentException("Membre introuvable : " + memberId));
    }

    private CheckInDTO toDTO(CheckIn c) {
        return CheckInDTO.builder()
                .id(c.getId())
                .memberId(c.getMember().getId())
                .memberFirstName(c.getMember().getFirstName())
                .memberLastName(c.getMember().getLastName())
                .memberEmail(c.getMember().getEmail())
                .profileImageUrl(c.getMember().getProfileImageUrl())
                .checkInTime(c.getCheckInTime())
                .checkOutTime(c.getCheckOutTime())
                .notes(c.getNotes())
                .build();
    }
}
