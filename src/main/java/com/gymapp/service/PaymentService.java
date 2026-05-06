package com.gymapp.service;

import com.gymapp.dto.PaymentDTO;
import com.gymapp.entity.enums.PaymentStatus;
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

    com.gymapp.dto.PaymentStatsDTO getStats();

    Page<PaymentDTO> getAll(com.gymapp.entity.enums.PaymentStatus status, Pageable pageable);
}
