package com.gymapp.member.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoyaltyBalanceDTO {
    private Long memberId;
    private String firstName;
    private String lastName;
    private Integer loyaltyPoints;
    private String tier;         // BRONZE, SILVER, GOLD, PLATINUM
    private Integer nextTierPoints; // points restants pour monter de tier
}
