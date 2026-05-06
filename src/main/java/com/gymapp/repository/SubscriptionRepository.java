package com.gymapp.repository;

import com.gymapp.entity.Subscription;
import com.gymapp.entity.enums.SubscriptionStatus;
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

    Page<Subscription> findByStatus(SubscriptionStatus status, Pageable pageable);

    long countByStatusAndEndDateBetween(SubscriptionStatus status, LocalDate start, LocalDate end);
}
