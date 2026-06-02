package com.gymapp.coach.dto;

import com.gymapp.coach.entity.enums.DifficultyLevel;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExerciseDTO {

    private Long id;

    @NotBlank(message = "Exercise name is required")
    private String name;

    private String description;
    private String muscleGroup;
    private DifficultyLevel difficultyLevel;
    private Long machineId;
    private String machineName;
    private String imageUrl;
}
