package com.gymapp.controller;

import com.gymapp.dto.MealDTO;
import com.gymapp.dto.NutritionPlanDTO;
import com.gymapp.service.NutritionService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/nutrition-plans")
@RequiredArgsConstructor
public class NutritionController {

    private final NutritionService nutritionService;

    // ── Nutrition Plans ──────────────────────────────────────────────────────

    @PostMapping("/creator/{creatorId}")
    public ResponseEntity<NutritionPlanDTO> createPlan(
            @PathVariable Long creatorId, @RequestBody NutritionPlanDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(nutritionService.createPlan(dto, creatorId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<NutritionPlanDTO> getPlanById(@PathVariable Long id) {
        return ResponseEntity.ok(nutritionService.getPlanById(id));
    }

    @GetMapping("/member/{memberId}")
    public ResponseEntity<Page<NutritionPlanDTO>> getPlansByMember(
            @PathVariable Long memberId, Pageable pageable) {
        return ResponseEntity.ok(nutritionService.getPlansByMember(memberId, pageable));
    }

    @GetMapping("/nutritionist/{nutritionistId}")
    public ResponseEntity<Page<NutritionPlanDTO>> getPlansByNutritionist(
            @PathVariable Long nutritionistId, Pageable pageable) {
        return ResponseEntity.ok(nutritionService.getPlansByNutritionist(nutritionistId, pageable));
    }

    @PutMapping("/{id}")
    public ResponseEntity<NutritionPlanDTO> updatePlan(
            @PathVariable Long id, @RequestBody NutritionPlanDTO dto) {
        return ResponseEntity.ok(nutritionService.updatePlan(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePlan(@PathVariable Long id) {
        nutritionService.deletePlan(id);
        return ResponseEntity.noContent().build();
    }

    // ── Meals ────────────────────────────────────────────────────────────────

    @PostMapping("/{planId}/meals")
    public ResponseEntity<MealDTO> addMeal(@PathVariable Long planId, @RequestBody MealDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(nutritionService.addMeal(planId, dto));
    }

    @PutMapping("/meals/{mealId}")
    public ResponseEntity<MealDTO> updateMeal(@PathVariable Long mealId, @RequestBody MealDTO dto) {
        return ResponseEntity.ok(nutritionService.updateMeal(mealId, dto));
    }

    @DeleteMapping("/meals/{mealId}")
    public ResponseEntity<Void> deleteMeal(@PathVariable Long mealId) {
        nutritionService.deleteMeal(mealId);
        return ResponseEntity.noContent().build();
    }
}
