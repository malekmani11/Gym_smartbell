package com.gymapp.nutrition.dto;

import com.gymapp.nutrition.entity.enums.ProgramStatus;
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
public class NutritionPlanDTO {

    private Long id;

    @NotBlank(message = "Title is required")
    private String title;

    private String description;
    private Long createdById;
    private String createdByName;

    @NotNull(message = "Member ID is required")
    private Long memberId;

    private String memberName;
    private LocalDate startDate;
    private LocalDate endDate;
    private String goal;
    private ProgramStatus status;
    private LocalDateTime createdAt;
    private List<MealDTO> meals;
}
