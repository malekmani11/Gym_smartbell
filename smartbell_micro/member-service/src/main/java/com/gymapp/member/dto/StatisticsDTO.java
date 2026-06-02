package com.gymapp.member.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StatisticsDTO {

    private Long totalMembers;
    private Long activeMembers;
    private Long totalCoaches;
    private BigDecimal revenueThisMonth;
    private BigDecimal revenueThisYear;
    private Long activeSubscriptions;
    private Long expiredSubscriptions;
    private Long totalCourses;
    private Long totalEvents;
    private Long openComplaints;

    // Advanced KPIs
    private Double attendanceRate;
    private Long brokenMachinesCount;
    private java.util.List<BigDecimal> revenueTrend;
    private java.util.List<Long> memberTrend;
    private Long maleCount;
    private Long femaleCount;
    private Long expiringSoonCount;
}
