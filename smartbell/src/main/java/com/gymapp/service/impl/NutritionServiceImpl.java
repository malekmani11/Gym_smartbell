package com.gymapp.service.impl;

import com.gymapp.dto.MealDTO;
import com.gymapp.dto.NutritionPlanDTO;
import com.gymapp.entity.*;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.*;
import com.gymapp.service.NutritionService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class NutritionServiceImpl implements NutritionService {

    private final NutritionPlanRepository planRepository;
    private final MealRepository mealRepository;
    private final MemberRepository memberRepository;
    private final UserRepository userRepository;
    private final EntityMapper mapper;

    @Override
    public NutritionPlanDTO createPlan(NutritionPlanDTO dto, Long creatorId) {
        log.info("Creating nutrition plan: {} for member: {}", dto.getTitle(), dto.getMemberId());
        User creator = userRepository.findById(creatorId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));
        Member member = memberRepository.findById(dto.getMemberId())
                .orElseThrow(() -> new EntityNotFoundException("Member not found"));

        NutritionPlan plan = NutritionPlan.builder()
                .title(dto.getTitle())
                .description(dto.getDescription())
                .createdBy(creator)
                .member(member)
                .startDate(dto.getStartDate())
                .endDate(dto.getEndDate())
                .goal(dto.getGoal())
                .build();

        NutritionPlan saved = planRepository.save(plan);

        // Add meals if provided
        if (dto.getMeals() != null) {
            for (MealDTO mealDTO : dto.getMeals()) {
                Meal meal = Meal.builder()
                        .nutritionPlan(saved)
                        .name(mealDTO.getName())
                        .mealType(mealDTO.getMealType())
                        .dayNumber(mealDTO.getDayNumber())
                        .calories(mealDTO.getCalories())
                        .proteinGrams(mealDTO.getProteinGrams())
                        .carbsGrams(mealDTO.getCarbsGrams())
                        .fatGrams(mealDTO.getFatGrams())
                        .description(mealDTO.getDescription())
                        .build();
                mealRepository.save(meal);
            }
        }

        return mapper.toNutritionPlanDTO(
            planRepository.findById(saved.getId())
                .orElseThrow(() -> new EntityNotFoundException("Nutrition plan not found after save: " + saved.getId()))
        );
    }

    @Override
    @Transactional(readOnly = true)
    public NutritionPlanDTO getPlanById(Long id) {
        return mapper.toNutritionPlanDTO(planRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Nutrition plan not found")));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<NutritionPlanDTO> getPlansByMember(Long memberId, Pageable pageable) {
        return planRepository.findByMemberId(memberId, pageable).map(mapper::toNutritionPlanDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<NutritionPlanDTO> getPlansByNutritionist(Long nutritionistId, Pageable pageable) {
        return planRepository.findByCreatedById(nutritionistId, pageable).map(mapper::toNutritionPlanDTO);
    }

    @Override
    public NutritionPlanDTO updatePlan(Long id, NutritionPlanDTO dto) {
        NutritionPlan plan = planRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Nutrition plan not found"));

        if (dto.getTitle() != null)
            plan.setTitle(dto.getTitle());
        if (dto.getDescription() != null)
            plan.setDescription(dto.getDescription());
        if (dto.getGoal() != null)
            plan.setGoal(dto.getGoal());
        if (dto.getStartDate() != null)
            plan.setStartDate(dto.getStartDate());
        if (dto.getEndDate() != null)
            plan.setEndDate(dto.getEndDate());
        if (dto.getStatus() != null)
            plan.setStatus(dto.getStatus());

        return mapper.toNutritionPlanDTO(planRepository.save(plan));
    }

    @Override
    public void deletePlan(Long id) {
        if (!planRepository.existsById(id))
            throw new EntityNotFoundException("Nutrition plan not found");
        planRepository.deleteById(id);
    }

    @Override
    public MealDTO addMeal(Long planId, MealDTO dto) {
        NutritionPlan plan = planRepository.findById(planId)
                .orElseThrow(() -> new EntityNotFoundException("Nutrition plan not found"));

        Meal meal = Meal.builder()
                .nutritionPlan(plan)
                .name(dto.getName())
                .mealType(dto.getMealType())
                .dayNumber(dto.getDayNumber())
                .calories(dto.getCalories())
                .proteinGrams(dto.getProteinGrams())
                .carbsGrams(dto.getCarbsGrams())
                .fatGrams(dto.getFatGrams())
                .description(dto.getDescription())
                .build();

        return mapper.toMealDTO(mealRepository.save(meal));
    }

    @Override
    public MealDTO updateMeal(Long mealId, MealDTO dto) {
        Meal meal = mealRepository.findById(mealId)
                .orElseThrow(() -> new EntityNotFoundException("Meal not found"));

        if (dto.getName() != null)
            meal.setName(dto.getName());
        if (dto.getMealType() != null)
            meal.setMealType(dto.getMealType());
        if (dto.getDayNumber() != null)
            meal.setDayNumber(dto.getDayNumber());
        if (dto.getCalories() != null)
            meal.setCalories(dto.getCalories());
        if (dto.getProteinGrams() != null)
            meal.setProteinGrams(dto.getProteinGrams());
        if (dto.getCarbsGrams() != null)
            meal.setCarbsGrams(dto.getCarbsGrams());
        if (dto.getFatGrams() != null)
            meal.setFatGrams(dto.getFatGrams());
        if (dto.getDescription() != null)
            meal.setDescription(dto.getDescription());

        return mapper.toMealDTO(mealRepository.save(meal));
    }

    @Override
    public void deleteMeal(Long mealId) {
        if (!mealRepository.existsById(mealId))
            throw new EntityNotFoundException("Meal not found");
        mealRepository.deleteById(mealId);
    }
}
