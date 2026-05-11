package com.gymapp.service.impl;

import com.gymapp.dto.SubscriptionPlanDTO;
import com.gymapp.entity.SubscriptionPlan;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.SubscriptionPlanRepository;
import com.gymapp.service.SubscriptionPlanService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class SubscriptionPlanServiceImpl implements SubscriptionPlanService {

    private final SubscriptionPlanRepository planRepository;
    private final EntityMapper mapper;

    @Override
    public SubscriptionPlanDTO createPlan(SubscriptionPlanDTO dto) {
        log.info("Creating subscription plan: {}", dto.getName());
        SubscriptionPlan plan = SubscriptionPlan.builder()
                .name(dto.getName())
                .description(dto.getDescription())
                .durationMonths(dto.getDurationMonths())
                .price(dto.getPrice())
                .active(true)
                .build();
        return mapper.toSubscriptionPlanDTO(planRepository.save(plan));
    }

    @Override
    @Transactional(readOnly = true)
    public SubscriptionPlanDTO getPlanById(Long id) {
        return mapper.toSubscriptionPlanDTO(planRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Plan not found with id: " + id)));
    }

    @Override
    @Transactional(readOnly = true)
    public List<SubscriptionPlanDTO> getAllActivePlans() {
        return planRepository.findByActiveTrue().stream()
                .map(this::toEnrichedDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<SubscriptionPlanDTO> getAllPlans() {
        return planRepository.findAll().stream()
                .map(this::toEnrichedDTO).collect(Collectors.toList());
    }

    private SubscriptionPlanDTO toEnrichedDTO(com.gymapp.entity.SubscriptionPlan plan) {
        SubscriptionPlanDTO dto = mapper.toSubscriptionPlanDTO(plan);
        dto.setSubscribersCount(planRepository.countActiveSubscribersByPlan(plan.getId()));
        dto.setTotalRevenue(planRepository.sumRevenueByPlan(plan.getId()));
        return dto;
    }

    @Override
    public SubscriptionPlanDTO updatePlan(Long id, SubscriptionPlanDTO dto) {
        log.info("Updating subscription plan: {}", id);
        SubscriptionPlan plan = planRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Plan not found with id: " + id));

        if (dto.getName() != null)
            plan.setName(dto.getName());
        if (dto.getDescription() != null)
            plan.setDescription(dto.getDescription());
        if (dto.getDurationMonths() != null)
            plan.setDurationMonths(dto.getDurationMonths());
        if (dto.getPrice() != null)
            plan.setPrice(dto.getPrice());
        if (dto.getActive() != null)
            plan.setActive(dto.getActive());

        return mapper.toSubscriptionPlanDTO(planRepository.save(plan));
    }

    @Override
    public void deletePlan(Long id) {
        log.warn("Deleting plan: {}", id);
        if (!planRepository.existsById(id)) {
            throw new EntityNotFoundException("Plan not found with id: " + id);
        }
        planRepository.deleteById(id);
    }
}
