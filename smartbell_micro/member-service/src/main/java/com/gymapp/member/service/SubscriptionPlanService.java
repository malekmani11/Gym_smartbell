package com.gymapp.member.service;

import com.gymapp.member.dto.SubscriptionPlanDTO;
import java.util.List;

public interface SubscriptionPlanService {

    SubscriptionPlanDTO createPlan(SubscriptionPlanDTO dto);

    SubscriptionPlanDTO getPlanById(Long id);

    List<SubscriptionPlanDTO> getAllActivePlans();

    List<SubscriptionPlanDTO> getAllPlans();

    SubscriptionPlanDTO updatePlan(Long id, SubscriptionPlanDTO dto);

    void deletePlan(Long id);
}
