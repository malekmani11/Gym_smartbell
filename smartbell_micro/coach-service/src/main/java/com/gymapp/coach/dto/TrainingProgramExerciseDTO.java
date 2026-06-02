package com.gymapp.coach.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TrainingProgramExerciseDTO {

    private Long id;

    @NotNull(message = "Exercise ID is required")
    private Long exerciseId;

    private String exerciseName;
    private Integer sets;
    private Integer reps;
    private Integer restSeconds;
    private Integer dayNumber;
    private Integer orderIndex;
}
