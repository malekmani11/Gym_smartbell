package com.gymapp.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class LoyaltyEarnRequest {

    @NotNull
    private Long memberId;

    @NotNull
    @Min(1)
    private Integer points;

    @NotBlank
    private String description;
}
