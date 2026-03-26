package com.gymapp.service.impl;

import com.gymapp.dto.SubscriptionDTO;
import com.gymapp.entity.*;
import com.gymapp.entity.enums.SubscriptionStatus;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.*;
import com.gymapp.service.SubscriptionService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
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
    private final CouponRepository couponRepository;
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

        // Apply coupon if provided
        if (dto.getCouponId() != null) {
            Coupon coupon = couponRepository.findById(dto.getCouponId())
                    .orElseThrow(() -> new EntityNotFoundException("Coupon not found"));

            if (!coupon.getActive()) {
                throw new IllegalStateException("Coupon is not active");
            }
            if (coupon.getValidUntil().isBefore(LocalDate.now())) {
                throw new IllegalStateException("Coupon has expired");
            }
            if (coupon.getMaxUses() != null && coupon.getCurrentUses() >= coupon.getMaxUses()) {
                throw new IllegalStateException("Coupon usage limit reached");
            }

            subscription.setCoupon(coupon);
            coupon.setCurrentUses(coupon.getCurrentUses() + 1);
            couponRepository.save(coupon);
        }

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
