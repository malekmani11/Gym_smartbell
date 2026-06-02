package com.gymapp.member.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class LoyaltyRedeemRequest {

    @NotNull
    private Long memberId;

    @NotNull
    @Min(1)
    private Integer points;
}
