package com.gymapp.service.impl;

import com.gymapp.dto.SubscriptionDTO;
import com.gymapp.entity.Subscription;
import com.gymapp.entity.SubscriptionPlan;
import com.gymapp.entity.User;
import com.gymapp.entity.enums.SubscriptionStatus;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.SubscriptionPlanRepository;
import com.gymapp.repository.SubscriptionRepository;
import com.gymapp.repository.UserRepository;
import com.gymapp.service.SubscriptionService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class SubscriptionServiceImpl implements SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;
    private final SubscriptionPlanRepository planRepository;
    private final EntityMapper mapper;

    @Override
    public SubscriptionDTO createSubscription(SubscriptionDTO dto) {
        log.info("Creating subscription for user: {} with plan: {}", dto.getUserId(), dto.getPlanId());

        User user = userRepository.findById(dto.getUserId())
                .orElseThrow(() -> new EntityNotFoundException("User not found"));
        SubscriptionPlan plan = planRepository.findById(dto.getPlanId())
                .orElseThrow(() -> new EntityNotFoundException("Plan not found"));

        LocalDate startDate = dto.getStartDate() != null ? dto.getStartDate() : LocalDate.now();
        LocalDate endDate = startDate.plusMonths(plan.getDurationMonths());

        Subscription subscription = Subscription.builder()
                .user(user)
                .plan(plan)
                .startDate(startDate)
                .endDate(endDate)
                .status(SubscriptionStatus.ACTIVE)
                .build();

        Subscription saved = subscriptionRepository.save(subscription);
        log.info("Subscription created: {}", saved.getId());
        return mapper.toSubscriptionDTO(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public SubscriptionDTO getSubscriptionById(Long id) {
        return mapper.toSubscriptionDTO(subscriptionRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Subscription not found with id: " + id)));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<SubscriptionDTO> getSubscriptionsByUser(Long userId, Pageable pageable) {
        return subscriptionRepository.findByUserId(userId, pageable).map(mapper::toSubscriptionDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<SubscriptionDTO> getSubscriptionsByStatus(SubscriptionStatus status, Pageable pageable) {
        return subscriptionRepository.findByStatus(status, pageable).map(mapper::toSubscriptionDTO);
    }

    @Override
    public SubscriptionDTO cancelSubscription(Long id) {
        log.info("Cancelling subscription: {}", id);
        Subscription subscription = subscriptionRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Subscription not found with id: " + id));
        subscription.setStatus(SubscriptionStatus.CANCELLED);
        return mapper.toSubscriptionDTO(subscriptionRepository.save(subscription));
    }

    @Override
    public SubscriptionDTO renewSubscription(Long id) {
        log.info("Renewing subscription: {}", id);
        Subscription subscription = subscriptionRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Subscription not found with id: " + id));
        SubscriptionPlan plan = subscription.getPlan();
        if (plan == null) {
            throw new EntityNotFoundException("Aucun plan associé à cet abonnement (id: " + id + ")");
        }
        LocalDate startDate = LocalDate.now();
        LocalDate endDate   = startDate.plusMonths(plan.getDurationMonths());
        subscription.setStartDate(startDate);
        subscription.setEndDate(endDate);
        subscription.setStatus(SubscriptionStatus.ACTIVE);
        return mapper.toSubscriptionDTO(subscriptionRepository.save(subscription));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<SubscriptionDTO> getAll(Pageable pageable) {
        return subscriptionRepository.findAll(pageable).map(mapper::toSubscriptionDTO);
    }

    @Override
    public void checkAndExpireSubscriptions() {
        log.info("Checking for expired subscriptions...");
        List<Subscription> expired = subscriptionRepository
                .findByStatusAndEndDateBefore(SubscriptionStatus.ACTIVE, LocalDate.now());
        expired.forEach(sub -> {
            sub.setStatus(SubscriptionStatus.EXPIRED);
            subscriptionRepository.save(sub);
            log.info("Subscription {} expired", sub.getId());
        });
    }
}
