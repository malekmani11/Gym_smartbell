package com.gymapp.member.service;

import com.gymapp.member.dto.SubscriptionDTO;
import com.gymapp.member.entity.enums.SubscriptionStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface SubscriptionService {

    SubscriptionDTO createSubscription(SubscriptionDTO dto);

    SubscriptionDTO getSubscriptionById(Long id);

    Page<SubscriptionDTO> getSubscriptionsByUser(Long userId, Pageable pageable);

    Page<SubscriptionDTO> getSubscriptionsByStatus(SubscriptionStatus status, Pageable pageable);

    SubscriptionDTO cancelSubscription(Long id);

    SubscriptionDTO renewSubscription(Long id);

    Page<SubscriptionDTO> getAll(Pageable pageable);

    void checkAndExpireSubscriptions();
}
