package com.gymapp.service.impl;

import com.gymapp.dto.PaymentDTO;
import com.gymapp.entity.Payment;
import com.gymapp.entity.Subscription;
import com.gymapp.entity.enums.PaymentStatus;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.PaymentRepository;
import com.gymapp.repository.SubscriptionRepository;
import com.gymapp.service.PaymentService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class PaymentServiceImpl implements PaymentService {

    private final PaymentRepository paymentRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final EntityMapper mapper;

    @Override
    public PaymentDTO createPayment(PaymentDTO dto) {
        log.info("Creating payment for subscription: {}", dto.getSubscriptionId());
        Subscription subscription = subscriptionRepository.findById(dto.getSubscriptionId())
                .orElseThrow(() -> new EntityNotFoundException("Subscription not found"));

        Payment payment = Payment.builder()
                .subscription(subscription)
                .amount(dto.getAmount())
                .paymentDate(LocalDateTime.now())
                .paymentMethod(dto.getPaymentMethod())
                .status(PaymentStatus.COMPLETED)
                .transactionRef(dto.getTransactionRef())
                .build();

        return mapper.toPaymentDTO(paymentRepository.save(payment));
    }

    @Override
    @Transactional(readOnly = true)
    public PaymentDTO getPaymentById(Long id) {
        return mapper.toPaymentDTO(paymentRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Payment not found with id: " + id)));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PaymentDTO> getPaymentsBySubscription(Long subscriptionId, Pageable pageable) {
        return paymentRepository.findBySubscriptionId(subscriptionId, pageable).map(mapper::toPaymentDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PaymentDTO> getPaymentsByUser(Long userId, Pageable pageable) {
        return paymentRepository.findBySubscriptionUserId(userId, pageable).map(mapper::toPaymentDTO);
    }

    @Override
    public PaymentDTO updatePaymentStatus(Long id, PaymentStatus status) {
        log.info("Updating payment {} status to {}", id, status);
        Payment payment = paymentRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Payment not found with id: " + id));
        payment.setStatus(status);
        return mapper.toPaymentDTO(paymentRepository.save(payment));
    }

    @Override
    @Transactional(readOnly = true)
    public BigDecimal getRevenueBetween(LocalDateTime start, LocalDateTime end) {
        BigDecimal revenue = paymentRepository.sumCompletedPaymentsBetween(start, end);
        return revenue != null ? revenue : BigDecimal.ZERO;
    }

    @Override
    @Transactional(readOnly = true)
    public com.gymapp.dto.PaymentStatsDTO getStats() {
        LocalDateTime now          = LocalDateTime.now();
        LocalDateTime startOfMonth = now.withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
        LocalDateTime startOfPrev  = startOfMonth.minusMonths(1);
        LocalDateTime endOfPrev    = startOfMonth.minusSeconds(1);

        BigDecimal thisMonth = paymentRepository.sumCompletedPaymentsBetween(startOfMonth, now);
        BigDecimal prevMonth = paymentRepository.sumCompletedPaymentsBetween(startOfPrev, endOfPrev);
        BigDecimal total     = paymentRepository.sumAllCompleted();

        return com.gymapp.dto.PaymentStatsDTO.builder()
                .revenueThisMonth(thisMonth != null ? thisMonth : BigDecimal.ZERO)
                .revenuePrevMonth(prevMonth != null ? prevMonth : BigDecimal.ZERO)
                .completedCount(paymentRepository.countByStatus(com.gymapp.entity.enums.PaymentStatus.COMPLETED))
                .pendingCount(paymentRepository.countByStatus(com.gymapp.entity.enums.PaymentStatus.PENDING))
                .failedCount(paymentRepository.countByStatus(com.gymapp.entity.enums.PaymentStatus.FAILED))
                .refundedCount(paymentRepository.countByStatus(com.gymapp.entity.enums.PaymentStatus.REFUNDED))
                .totalRevenue(total != null ? total : BigDecimal.ZERO)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PaymentDTO> getAll(PaymentStatus status, Pageable pageable) {
        if (status != null) {
            return paymentRepository.findByStatus(status, pageable).map(mapper::toPaymentDTO);
        }
        return paymentRepository.findAll(pageable).map(mapper::toPaymentDTO);
    }
}
