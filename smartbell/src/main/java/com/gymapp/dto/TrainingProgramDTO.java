package com.gymapp.dto;

import com.gymapp.entity.enums.ProgramStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TrainingProgramDTO {

    private Long id;

    @NotBlank(message = "Program name is required")
    private String name;

    private String description;

    @NotNull(message = "Coach ID is required")
    private Long coachId;

    private String coachName;

    @NotNull(message = "Member ID is required")
    private Long memberId;

    private String memberName;
    private LocalDate startDate;
    private LocalDate endDate;
    private ProgramStatus status;
    private LocalDateTime createdAt;
    private List<TrainingProgramExerciseDTO> exercises;
}
