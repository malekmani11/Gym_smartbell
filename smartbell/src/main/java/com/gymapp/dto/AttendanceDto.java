package com.gymapp.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceDto {

    private Long id;
    private Long courseId;
    private String courseName;
    private Long memberId;
    private String memberFirstName;
    private String memberLastName;
    private LocalDate sessionDate;
    private Boolean present;
    private String notes;
    private LocalDateTime createdAt;
}
