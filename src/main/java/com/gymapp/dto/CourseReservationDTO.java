package com.gymapp.dto;

import com.gymapp.entity.enums.ReservationStatus;
import jakarta.validation.constraints.NotNull;
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
public class CourseReservationDTO {

    private Long id;

    @NotNull(message = "Course ID is required")
    private Long courseId;

    private String courseName;

    @NotNull(message = "Member ID is required")
    private Long memberId;

    private String memberName;

    @NotNull(message = "Reservation date is required")
    private LocalDate reservationDate;

    private ReservationStatus status;
    private LocalDateTime createdAt;
}
