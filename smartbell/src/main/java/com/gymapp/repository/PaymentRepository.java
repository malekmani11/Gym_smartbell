package com.gymapp.repository;

import com.gymapp.entity.Payment;
import com.gymapp.entity.enums.PaymentStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    Page<Payment> findBySubscriptionId(Long subscriptionId, Pageable pageable);

    Page<Payment> findBySubscriptionUserId(Long userId, Pageable pageable);

    List<Payment> findByStatus(PaymentStatus status);

    @Query("SELECT SUM(p.amount) FROM Payment p WHERE p.status = 'COMPLETED' AND p.paymentDate BETWEEN :start AND :end")
    BigDecimal sumCompletedPaymentsBetween(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    long countByStatus(PaymentStatus status);

    Page<Payment> findByStatus(PaymentStatus status, Pageable pageable);

    /** Only payments that have a valid (non-orphaned) subscription. */
    @Query("SELECT p FROM Payment p JOIN p.subscription s JOIN s.user u")
    Page<Payment> findAllWithValidSubscription(Pageable pageable);

    @Query("SELECT p FROM Payment p JOIN p.subscription s JOIN s.user u WHERE p.status = :status")
    Page<Payment> findByStatusWithValidSubscription(@Param("status") PaymentStatus status, Pageable pageable);

    Page<Payment> findByPaymentDateBetween(LocalDateTime from, LocalDateTime to, Pageable pageable);

    @Query("SELECT SUM(p.amount) FROM Payment p WHERE p.status = 'COMPLETED'")
    BigDecimal sumAllCompleted();

    /** Count COMPLETED payments for the same member in the same month/year (duplicate guard). */
    @Query("SELECT COUNT(p) FROM Payment p " +
           "JOIN p.subscription s " +
           "JOIN s.user u " +
           "WHERE u.id = :userId " +
           "AND p.status = 'COMPLETED' " +
           "AND YEAR(p.paymentDate) = :year " +
           "AND MONTH(p.paymentDate) = :month")
    long countCompletedPaymentsForUserInMonth(@Param("userId") Long userId,
                                              @Param("year") int year,
                                              @Param("month") int month);
}
