package com.gymapp.controller;

import com.gymapp.dto.SubscriptionDTO;
import com.gymapp.entity.enums.SubscriptionStatus;
import com.gymapp.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/subscriptions")
@RequiredArgsConstructor
public class SubscriptionController {

    private final SubscriptionService subscriptionService;

    @PostMapping
    public ResponseEntity<SubscriptionDTO> createSubscription(@RequestBody SubscriptionDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(subscriptionService.createSubscription(dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<SubscriptionDTO> getSubscriptionById(@PathVariable Long id) {
        return ResponseEntity.ok(subscriptionService.getSubscriptionById(id));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<Page<SubscriptionDTO>> getSubscriptionsByUser(
            @PathVariable Long userId, Pageable pageable) {
        return ResponseEntity.ok(subscriptionService.getSubscriptionsByUser(userId, pageable));
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<Page<SubscriptionDTO>> getSubscriptionsByStatus(
            @PathVariable SubscriptionStatus status, Pageable pageable) {
        return ResponseEntity.ok(subscriptionService.getSubscriptionsByStatus(status, pageable));
    }

    @GetMapping
    public ResponseEntity<Page<SubscriptionDTO>> getAllSubscriptions(Pageable pageable) {
        return ResponseEntity.ok(subscriptionService.getAll(pageable));
    }

    @PatchMapping("/{id}/cancel")
    public ResponseEntity<SubscriptionDTO> cancelSubscription(@PathVariable Long id) {
        return ResponseEntity.ok(subscriptionService.cancelSubscription(id));
    }
}
