package com.gymapp.coach.dto;

import com.gymapp.coach.entity.enums.AvailabilityStatus;
import com.gymapp.coach.entity.enums.Specialization;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CoachDTO {

    private Long id;
    private Long userId;
    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private Specialization specialization;
    private String bio;
    private String certification;
    private LocalDate hireDate;
    private AvailabilityStatus availabilityStatus;
    private String profileImageUrl;
    private Double ratingAvg;
    private LocalDate absenceStart;
    private LocalDate absenceEnd;
    private String absenceReason;
}
