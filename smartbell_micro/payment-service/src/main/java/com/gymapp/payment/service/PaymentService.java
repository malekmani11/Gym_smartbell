package com.gymapp.payment.service;

import com.gymapp.payment.dto.PaymentDTO;
import com.gymapp.payment.dto.PaymentStatsDTO;
import com.gymapp.payment.entity.enums.PaymentStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public interface PaymentService {

    PaymentDTO createPayment(PaymentDTO dto);

    PaymentDTO getPaymentById(Long id);

    Page<PaymentDTO> getPaymentsBySubscription(Long subscriptionId, Pageable pageable);

    Page<PaymentDTO> getPaymentsByUser(Long userId, Pageable pageable);

    PaymentDTO updatePaymentStatus(Long id, PaymentStatus status);

    BigDecimal getRevenueBetween(LocalDateTime start, LocalDateTime end);

    PaymentStatsDTO getStats();

    Page<PaymentDTO> getAll(PaymentStatus status, Pageable pageable);

    void deletePayment(Long id);

    PaymentDTO updatePayment(Long id, PaymentDTO dto);
}
