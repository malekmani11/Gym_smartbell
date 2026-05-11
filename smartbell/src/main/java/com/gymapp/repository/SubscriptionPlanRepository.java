package com.gymapp.repository;

import com.gymapp.entity.SubscriptionPlan;
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

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM Payment p JOIN p.subscription s WHERE s.plan.id = :planId AND p.status = 'COMPLETED'")
    BigDecimal sumRevenueByPlan(@Param("planId") Long planId);
}
