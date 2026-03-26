package com.gymapp.service;

import com.gymapp.dto.SubscriptionDTO;
import com.gymapp.entity.enums.SubscriptionStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface SubscriptionService {

    SubscriptionDTO createSubscription(SubscriptionDTO dto);

    SubscriptionDTO getSubscriptionById(Long id);

    Page<SubscriptionDTO> getSubscriptionsByUser(Long userId, Pageable pageable);

    Page<SubscriptionDTO> getSubscriptionsByStatus(SubscriptionStatus status, Pageable pageable);

    SubscriptionDTO cancelSubscription(Long id);

    void checkAndExpireSubscriptions();
}
