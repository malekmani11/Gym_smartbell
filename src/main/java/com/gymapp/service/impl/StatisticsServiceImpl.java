package com.gymapp.service.impl;

import com.gymapp.dto.StatisticsDTO;
import com.gymapp.entity.enums.ComplaintStatus;
import com.gymapp.entity.enums.MembershipStatus;
import com.gymapp.entity.enums.SubscriptionStatus;
import com.gymapp.repository.*;
import com.gymapp.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class StatisticsServiceImpl implements StatisticsService {

    private final MemberRepository memberRepository;
    private final CoachRepository coachRepository;
    private final CheckInRepository checkInRepository;
    private final PaymentRepository paymentRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final CourseRepository courseRepository;
    private final EventRepository eventRepository;
    private final ComplaintRepository complaintRepository;

    @Override
    public StatisticsDTO getGymStatistics() {
        log.debug("Generating gym statistics");

        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = LocalDate.now().atTime(LocalTime.MAX);
        LocalDateTime startOfMonth = LocalDate.now().withDayOfMonth(1).atStartOfDay();
        LocalDateTime startOfYear = LocalDate.now().withDayOfYear(1).atStartOfDay();

        BigDecimal revenueMonth = paymentRepository.sumCompletedPaymentsBetween(startOfMonth, endOfDay);
        BigDecimal revenueYear = paymentRepository.sumCompletedPaymentsBetween(startOfYear, endOfDay);

        return StatisticsDTO.builder()
                .totalMembers(memberRepository.count())
                .activeMembers(memberRepository.findByMembershipStatus(MembershipStatus.ACTIVE, Pageable.unpaged())
                        .getTotalElements())
                .totalCoaches(coachRepository.count())
                .totalCheckInsToday(checkInRepository.countCheckInsBetween(startOfDay, endOfDay))
                .totalCheckInsThisMonth(checkInRepository.countCheckInsBetween(startOfMonth, endOfDay))
                .revenueThisMonth(revenueMonth != null ? revenueMonth : BigDecimal.ZERO)
                .revenueThisYear(revenueYear != null ? revenueYear : BigDecimal.ZERO)
                .activeSubscriptions(subscriptionRepository.findByStatus(SubscriptionStatus.ACTIVE, Pageable.unpaged())
                        .getTotalElements())
                .expiredSubscriptions(subscriptionRepository
                        .findByStatus(SubscriptionStatus.EXPIRED, Pageable.unpaged()).getTotalElements())
                .totalCourses((long) courseRepository.findByActiveTrue(Pageable.unpaged()).getTotalElements())
                .totalEvents((long) eventRepository.findByActiveTrue(Pageable.unpaged()).getTotalElements())
                .openComplaints(
                        complaintRepository.findByStatus(ComplaintStatus.OPEN, Pageable.unpaged()).getTotalElements())
                .build();
    }
}
