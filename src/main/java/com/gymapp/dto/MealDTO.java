package com.gymapp.dto;

import com.gymapp.entity.enums.MealType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MealDTO {

    private Long id;
    private Long nutritionPlanId;

    @NotBlank(message = "Meal name is required")
    private String name;

    @NotNull(message = "Meal type is required")
    private MealType mealType;

    private Integer dayNumber;
    private Integer calories;
    private BigDecimal proteinGrams;
    private BigDecimal carbsGrams;
    private BigDecimal fatGrams;
    private String description;
}
