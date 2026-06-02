package com.gymapp.payment.mapper;

import com.gymapp.payment.dto.PaymentDTO;
import com.gymapp.payment.dto.SubscriptionDTO;
import com.gymapp.payment.dto.SubscriptionPlanDTO;
import com.gymapp.payment.entity.Payment;
import com.gymapp.payment.entity.Subscription;
import com.gymapp.payment.entity.SubscriptionPlan;
import org.springframework.stereotype.Component;

@Component
public class EntityMapper {

    public PaymentDTO toPaymentDTO(Payment payment) {
        if (payment == null) return null;
        return PaymentDTO.builder()
                .id(payment.getId())
                .subscriptionId(payment.getSubscription() != null ? payment.getSubscription().getId() : null)
                .amount(payment.getAmount())
                .paymentDate(payment.getPaymentDate())
                .paymentMethod(payment.getPaymentMethod())
                .status(payment.getStatus())
                .transactionRef(payment.getTransactionRef())
                .build();
    }

    public SubscriptionDTO toSubscriptionDTO(Subscription subscription) {
        if (subscription == null) return null;
        return SubscriptionDTO.builder()
                .id(subscription.getId())
                .userId(subscription.getUser() != null ? subscription.getUser().getId() : null)
                .planId(subscription.getPlan() != null ? subscription.getPlan().getId() : null)
                .planName(subscription.getPlan() != null ? subscription.getPlan().getName() : null)
                .startDate(subscription.getStartDate())
                .endDate(subscription.getEndDate())
                .status(subscription.getStatus())
                .createdAt(subscription.getCreatedAt())
                .build();
    }

    public SubscriptionPlanDTO toSubscriptionPlanDTO(SubscriptionPlan plan) {
        if (plan == null) return null;
        return SubscriptionPlanDTO.builder()
                .id(plan.getId())
                .name(plan.getName())
                .description(plan.getDescription())
                .durationMonths(plan.getDurationMonths())
                .price(plan.getPrice())
                .active(plan.getActive())
                .build();
    }
}
