package com.gymapp.nutrition.repository;

import com.gymapp.nutrition.entity.NutritionPlan;
import com.gymapp.nutrition.entity.enums.ProgramStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NutritionPlanRepository extends JpaRepository<NutritionPlan, Long> {

    Page<NutritionPlan> findByMemberId(Long memberId, Pageable pageable);

    Page<NutritionPlan> findByCreatedById(Long nutritionistId, Pageable pageable);

    List<NutritionPlan> findByMemberIdAndStatus(Long memberId, ProgramStatus status);
}
