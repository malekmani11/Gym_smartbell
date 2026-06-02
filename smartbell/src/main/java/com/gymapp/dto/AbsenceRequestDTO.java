package com.gymapp.dto;

import com.gymapp.entity.enums.AbsenceStatus;
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
public class AbsenceRequestDTO {
    private Long id;
    private Long coachId;
    private String coachFirstName;
    private String coachLastName;
    private String coachEmail;
    private LocalDate startDate;
    private LocalDate endDate;
    private String reason;
    private AbsenceStatus status;
    private String adminNote;
    private LocalDateTime createdAt;
    private LocalDateTime reviewedAt;
}
