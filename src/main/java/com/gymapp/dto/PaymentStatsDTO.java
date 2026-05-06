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
public class PaymentStatsDTO {

    private BigDecimal revenueThisMonth;
    private BigDecimal revenuePrevMonth;
    private Long completedCount;
    private Long pendingCount;
    private Long failedCount;
    private Long refundedCount;
    private BigDecimal totalRevenue;
}
