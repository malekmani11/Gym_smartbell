package com.gymapp.repository;

import com.gymapp.entity.Meal;
import com.gymapp.entity.enums.MealType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MealRepository extends JpaRepository<Meal, Long> {

    List<Meal> findByNutritionPlanId(Long planId);

    List<Meal> findByNutritionPlanIdAndDayNumber(Long planId, Integer dayNumber);

    List<Meal> findByNutritionPlanIdAndMealType(Long planId, MealType mealType);
}
