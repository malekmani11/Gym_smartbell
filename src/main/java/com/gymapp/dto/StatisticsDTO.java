package com.gymapp.dto;

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
    private Long totalCheckInsToday;
    private Long totalCheckInsThisMonth;
    private BigDecimal revenueThisMonth;
    private BigDecimal revenueThisYear;
    private Long activeSubscriptions;
    private Long expiredSubscriptions;
    private Long totalCourses;
    private Long totalEvents;
    private Long openComplaints;
}
