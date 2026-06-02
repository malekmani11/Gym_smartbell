package com.gymapp.payment.service;

import com.gymapp.payment.dto.SubscriptionPlanDTO;
import java.util.List;

public interface SubscriptionPlanService {

    SubscriptionPlanDTO createPlan(SubscriptionPlanDTO dto);

    SubscriptionPlanDTO getPlanById(Long id);

    List<SubscriptionPlanDTO> getAllActivePlans();

    List<SubscriptionPlanDTO> getAllPlans();

    SubscriptionPlanDTO updatePlan(Long id, SubscriptionPlanDTO dto);

    void deletePlan(Long id);
}
