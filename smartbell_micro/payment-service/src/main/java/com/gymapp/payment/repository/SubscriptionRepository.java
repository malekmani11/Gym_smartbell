package com.gymapp.payment.repository;

import com.gymapp.payment.entity.Subscription;
import com.gymapp.payment.entity.enums.SubscriptionStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {

    Page<Subscription> findByUserId(Long userId, Pageable pageable);

    List<Subscription> findByUserIdAndStatus(Long userId, SubscriptionStatus status);

    List<Subscription> findByStatusAndEndDateBefore(SubscriptionStatus status, LocalDate date);

    List<Subscription> findByStatusAndEndDateBetween(SubscriptionStatus status, LocalDate from, LocalDate to);

    Page<Subscription> findByStatus(SubscriptionStatus status, Pageable pageable);

    long countByStatusAndEndDateBetween(SubscriptionStatus status, LocalDate start, LocalDate end);
}
