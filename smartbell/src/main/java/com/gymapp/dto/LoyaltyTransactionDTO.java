package com.gymapp.dto;

import com.gymapp.entity.enums.LoyaltyTransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoyaltyTransactionDTO {
    private Long id;
    private Long memberId;
    private LoyaltyTransactionType type;
    private Integer points;
    private String description;
    private LocalDateTime createdAt;
}
