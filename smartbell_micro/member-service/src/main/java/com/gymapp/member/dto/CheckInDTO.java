package com.gymapp.member.dto;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CheckInDTO {
    private Long id;
    private Long memberId;
    private String memberName;
    private LocalDateTime checkInTime;
    private String status;
    private Integer pointsAwarded;
    private String note;
    private String subscriptionStatus;
    private String expiryDate;
}
