package com.gymapp.nutrition.mapper;

import com.gymapp.nutrition.dto.MealDTO;
import com.gymapp.nutrition.dto.NutritionPlanDTO;
import com.gymapp.nutrition.entity.Meal;
import com.gymapp.nutrition.entity.NutritionPlan;
import org.springframework.stereotype.Component;

import java.util.stream.Collectors;

@Component
public class EntityMapper {

    public NutritionPlanDTO toNutritionPlanDTO(NutritionPlan plan) {
        if (plan == null) return null;
        return NutritionPlanDTO.builder()
                .id(plan.getId())
                .title(plan.getTitle())
                .description(plan.getDescription())
                .createdById(plan.getCreatedBy() != null ? plan.getCreatedBy().getId() : null)
                .createdByName(plan.getCreatedBy() != null
                        ? plan.getCreatedBy().getFirstName() + " " + plan.getCreatedBy().getLastName() : null)
                .memberId(plan.getMemberId())
                .startDate(plan.getStartDate())
                .endDate(plan.getEndDate())
                .goal(plan.getGoal())
                .status(plan.getStatus())
                .createdAt(plan.getCreatedAt())
                .meals(plan.getMeals() != null
                        ? plan.getMeals().stream().map(this::toMealDTO).collect(Collectors.toList())
                        : null)
                .build();
    }

    public MealDTO toMealDTO(Meal meal) {
        if (meal == null) return null;
        return MealDTO.builder()
                .id(meal.getId())
                .name(meal.getName())
                .mealType(meal.getMealType())
                .dayNumber(meal.getDayNumber())
                .calories(meal.getCalories())
                .proteinGrams(meal.getProteinGrams())
                .carbsGrams(meal.getCarbsGrams())
                .fatGrams(meal.getFatGrams())
                .description(meal.getDescription())
                .build();
    }
}
