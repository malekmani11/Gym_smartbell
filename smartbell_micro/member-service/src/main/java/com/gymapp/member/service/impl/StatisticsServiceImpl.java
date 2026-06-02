package com.gymapp.member.service.impl;

import com.gymapp.member.dto.StatisticsDTO;
import com.gymapp.member.entity.enums.Gender;
import com.gymapp.member.entity.enums.MembershipStatus;
import com.gymapp.member.entity.enums.SubscriptionStatus;
import com.gymapp.member.repository.MemberRepository;
import com.gymapp.member.repository.SubscriptionRepository;
import com.gymapp.member.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class StatisticsServiceImpl implements StatisticsService {

    private final MemberRepository       memberRepository;
    private final SubscriptionRepository subscriptionRepository;

    @Override
    public StatisticsDTO getGymStatistics() {
        log.debug("Generating gym statistics (member-service scope)");

        LocalDateTime endOfDay     = LocalDate.now().atTime(LocalTime.MAX);
        LocalDateTime startOfMonth = LocalDate.now().withDayOfMonth(1).atStartOfDay();
        LocalDateTime startOfYear  = LocalDate.now().withDayOfYear(1).atStartOfDay();

        long totalMembers  = memberRepository.count();
        long activeMembers = memberRepository
                .findByMembershipStatus(MembershipStatus.ACTIVE, Pageable.unpaged())
                .getTotalElements();

        // Tendance membres — 6 derniers mois
        List<BigDecimal> revenueTrend = new ArrayList<>();
        List<Long>       memberTrend  = new ArrayList<>();
        for (int i = 5; i >= 0; i--) {
            LocalDateTime start = LocalDate.now().minusMonths(i).withDayOfMonth(1).atStartOfDay();
            LocalDateTime end   = LocalDate.now().minusMonths(i)
                    .with(TemporalAdjusters.lastDayOfMonth()).atTime(LocalTime.MAX);

            long newMembers = memberRepository.findAll().stream()
                    .filter(m -> m.getCreatedAt() != null
                            && !m.getCreatedAt().isBefore(start)
                            && !m.getCreatedAt().isAfter(end))
                    .count();
            revenueTrend.add(BigDecimal.ZERO); // fourni par payment-service
            memberTrend.add(newMembers);
        }

        return StatisticsDTO.builder()
                .totalMembers(totalMembers)
                .activeMembers(activeMembers)
                .totalCoaches(0L)               // fourni par coach-service
                .revenueThisMonth(BigDecimal.ZERO) // fourni par payment-service
                .revenueThisYear(BigDecimal.ZERO)  // fourni par payment-service
                .activeSubscriptions(subscriptionRepository
                        .findByStatus(SubscriptionStatus.ACTIVE, Pageable.unpaged()).getTotalElements())
                .expiredSubscriptions(subscriptionRepository
                        .findByStatus(SubscriptionStatus.EXPIRED, Pageable.unpaged()).getTotalElements())
                .totalCourses(0L)               // fourni par coach-service
                .totalEvents(0L)                // fourni par event-service
                .openComplaints(0L)             // fourni par complaint-service
                .attendanceRate(totalMembers > 0 ? (double) activeMembers / totalMembers * 100 : 0.0)
                .brokenMachinesCount(0L)        // fourni par machine-service
                .revenueTrend(revenueTrend)
                .memberTrend(memberTrend)
                .maleCount(memberRepository.countByGender(Gender.MALE))
                .femaleCount(memberRepository.countByGender(Gender.FEMALE))
                .expiringSoonCount(subscriptionRepository.countByStatusAndEndDateBetween(
                        SubscriptionStatus.ACTIVE, LocalDate.now(), LocalDate.now().plusDays(7)))
                .build();
    }
}
