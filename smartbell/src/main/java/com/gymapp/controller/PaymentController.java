package com.gymapp.controller;

import com.gymapp.dto.PaymentDTO;
import com.gymapp.dto.PaymentStatsDTO;
import com.gymapp.entity.enums.PaymentStatus;
import com.gymapp.service.PaymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    @PostMapping
    public ResponseEntity<PaymentDTO> createPayment(@RequestBody PaymentDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(paymentService.createPayment(dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<PaymentDTO> getPaymentById(@PathVariable Long id) {
        return ResponseEntity.ok(paymentService.getPaymentById(id));
    }

    @GetMapping("/subscription/{subscriptionId}")
    public ResponseEntity<Page<PaymentDTO>> getPaymentsBySubscription(
            @PathVariable Long subscriptionId, Pageable pageable) {
        return ResponseEntity.ok(paymentService.getPaymentsBySubscription(subscriptionId, pageable));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<Page<PaymentDTO>> getPaymentsByUser(
            @PathVariable Long userId, Pageable pageable) {
        return ResponseEntity.ok(paymentService.getPaymentsByUser(userId, pageable));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<PaymentDTO> updatePaymentStatus(
            @PathVariable Long id, @RequestParam PaymentStatus status) {
        return ResponseEntity.ok(paymentService.updatePaymentStatus(id, status));
    }

    @GetMapping
    public ResponseEntity<Page<PaymentDTO>> getAll(
            @RequestParam(required = false) PaymentStatus status,
            Pageable pageable) {
        return ResponseEntity.ok(paymentService.getAll(status, pageable));
    }

    @GetMapping("/stats")
    public ResponseEntity<PaymentStatsDTO> getStats() {
        return ResponseEntity.ok(paymentService.getStats());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePayment(@PathVariable Long id) {
        paymentService.deletePayment(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}")
    public ResponseEntity<PaymentDTO> updatePayment(@PathVariable Long id, @RequestBody PaymentDTO dto) {
        return ResponseEntity.ok(paymentService.updatePayment(id, dto));
    }
}
