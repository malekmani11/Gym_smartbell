package com.gymapp.service;

import com.gymapp.dto.NutritionPlanDTO;
import com.gymapp.dto.MealDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface NutritionService {

    NutritionPlanDTO createPlan(NutritionPlanDTO dto, Long creatorId);

    NutritionPlanDTO getPlanById(Long id);

    Page<NutritionPlanDTO> getPlansByMember(Long memberId, Pageable pageable);

    Page<NutritionPlanDTO> getPlansByNutritionist(Long nutritionistId, Pageable pageable);

    NutritionPlanDTO updatePlan(Long id, NutritionPlanDTO dto);

    void deletePlan(Long id);

    MealDTO addMeal(Long planId, MealDTO dto);

    MealDTO updateMeal(Long mealId, MealDTO dto);

    void deleteMeal(Long mealId);
}
