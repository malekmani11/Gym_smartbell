package com.gymapp.dto;

import com.gymapp.entity.enums.DayOfWeek;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourseDTO {

    private Long id;

    @NotBlank(message = "Course name is required")
    private String name;

    private String description;

    @NotNull(message = "Coach ID is required")
    private Long coachId;

    private String coachName;

    @NotNull(message = "Day of week is required")
    private DayOfWeek dayOfWeek;

    @NotNull(message = "Start time is required")
    private LocalTime startTime;

    @NotNull(message = "End time is required")
    private LocalTime endTime;

    @NotNull(message = "Max participants is required")
    @Positive
    private Integer maxParticipants;

    private String location;
    private Boolean active;
    private Integer currentParticipants;

    private Long   salleId;
    private String salleName;
}
