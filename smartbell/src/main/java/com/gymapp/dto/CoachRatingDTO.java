package com.gymapp.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CoachRatingDTO {

    private Long id;
    private Long coachId;
    private Long memberId;
    private String memberName;
    private Integer rating;
    private String comment;
    private LocalDateTime createdAt;
}
