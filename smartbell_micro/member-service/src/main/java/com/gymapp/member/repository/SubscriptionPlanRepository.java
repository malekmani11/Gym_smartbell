package com.gymapp.member.repository;

import com.gymapp.member.entity.SubscriptionPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface SubscriptionPlanRepository extends JpaRepository<SubscriptionPlan, Long> {

    List<SubscriptionPlan> findByActiveTrue();

    @Query("SELECT COUNT(s) FROM Subscription s WHERE s.plan.id = :planId AND s.status = 'ACTIVE'")
    long countActiveSubscribersByPlan(@Param("planId") Long planId);

    // Revenue réel fourni par payment-service — retourne 0 ici par défaut
    default BigDecimal sumRevenueByPlan(Long planId) {
        return BigDecimal.ZERO;
    }
}
