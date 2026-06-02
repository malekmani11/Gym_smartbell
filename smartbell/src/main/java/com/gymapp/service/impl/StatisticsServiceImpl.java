package com.gymapp.service.impl;

import com.gymapp.dto.CheckInDTO;
import com.gymapp.dto.StatisticsDTO;
import com.gymapp.entity.enums.ComplaintStatus;
import com.gymapp.entity.enums.Gender;
import com.gymapp.entity.enums.MachineStatus;
import com.gymapp.entity.enums.MembershipStatus;
import com.gymapp.entity.enums.SubscriptionStatus;
import com.gymapp.repository.*;
import com.gymapp.service.CheckInService;
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
import java.util.ArrayList;
import java.util.List;
import java.util.function.LongSupplier;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class StatisticsServiceImpl implements StatisticsService {

    private final MemberRepository memberRepository;
    private final CoachRepository coachRepository;
    private final PaymentRepository paymentRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final CourseRepository courseRepository;
    private final EventRepository eventRepository;
    private final ComplaintRepository complaintRepository;
    private final MachineRepository machineRepository;
    private final CheckInService checkInService;

    @Override
    public StatisticsDTO getGymStatistics() {
        log.debug("Generating gym statistics");

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime endOfDay = LocalDate.now().atTime(LocalTime.MAX);
        LocalDateTime startOfMonth = LocalDate.now().withDayOfMonth(1).atStartOfDay();
        LocalDateTime startOfYear = LocalDate.now().withDayOfYear(1).atStartOfDay();

        BigDecimal revenueMonth = paymentRepository.sumCompletedPaymentsBetween(startOfMonth, endOfDay);
        BigDecimal revenueYear = paymentRepository.sumCompletedPaymentsBetween(startOfYear, endOfDay);

        // Trends (Last 6 months)
        List<BigDecimal> revenueTrend = new ArrayList<>();
        List<Long> memberTrend = new ArrayList<>();
        for (int i = 5; i >= 0; i--) {
            LocalDateTime start = LocalDate.now().minusMonths(i).withDayOfMonth(1).atStartOfDay();
            LocalDateTime end = LocalDate.now().minusMonths(i).with(java.time.temporal.TemporalAdjusters.lastDayOfMonth()).atTime(LocalTime.MAX);
            
            BigDecimal rev = paymentRepository.sumCompletedPaymentsBetween(start, end);
            revenueTrend.add(rev != null ? rev : BigDecimal.ZERO);
            
            // Count members who joined during this specific month
            long newMembers = memberRepository.findAll().stream()
                .filter(m -> m.getCreatedAt() != null && !m.getCreatedAt().isBefore(start) && !m.getCreatedAt().isAfter(end))
                .count();
            memberTrend.add(newMembers);
        }

        long totalMembers = memberRepository.count();
        long activeMembers = memberRepository.findByMembershipStatus(MembershipStatus.ACTIVE, Pageable.unpaged()).getTotalElements();

        return StatisticsDTO.builder()
                .totalMembers(totalMembers)
                .activeMembers(activeMembers)
                .totalCoaches(coachRepository.count())
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
                .attendanceRate(totalMembers > 0 ? (double) activeMembers / totalMembers * 100 : 0.0)
                .brokenMachinesCount(machineRepository.countByStatus(MachineStatus.OUT_OF_SERVICE) + machineRepository.countByStatus(MachineStatus.MAINTENANCE))
                .revenueTrend(revenueTrend)
                .memberTrend(memberTrend)
                .maleCount(memberRepository.countByGender(Gender.MALE))
                .femaleCount(memberRepository.countByGender(Gender.FEMALE))
                .expiringSoonCount(subscriptionRepository.countByStatusAndEndDateBetween(SubscriptionStatus.ACTIVE, LocalDate.now(), LocalDate.now().plusDays(7)))
                .checkInsToday(safeCount(() -> checkInService.countToday()))
                .checkInsThisWeek(safeCount(() -> checkInService.countThisWeek()))
                .checkInsThisMonth(safeCount(() -> checkInService.countThisMonth()))
                .recentCheckIns(safeCheckIns())
                .build();
    }

    private long safeCount(LongSupplier supplier) {
        try { return supplier.getAsLong(); } catch (Exception e) { return 0L; }
    }

    private List<CheckInDTO> safeCheckIns() {
        try { return checkInService.getTodayCheckIns().stream().limit(5).toList(); }
        catch (Exception e) { return List.of(); }
    }
}
