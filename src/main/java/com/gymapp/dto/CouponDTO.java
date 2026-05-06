package com.gymapp.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CouponDTO {

    private Long id;

    @NotBlank(message = "Coupon code is required")
    private String code;

    @Positive(message = "Discount must be positive")
    private BigDecimal discountPercentage;

    private LocalDate validFrom;
    private LocalDate validUntil;
    private Integer maxUses;
    private Integer currentUses;
    private Boolean active;
}
