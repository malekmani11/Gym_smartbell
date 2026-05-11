package com.gymapp.controller;

import com.gymapp.dto.LoyaltyBalanceDTO;
import com.gymapp.dto.LoyaltyEarnRequest;
import com.gymapp.dto.LoyaltyRedeemRequest;
import com.gymapp.dto.LoyaltyTransactionDTO;
import com.gymapp.service.LoyaltyService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/loyalty")
@RequiredArgsConstructor
public class LoyaltyController {

    private final LoyaltyService loyaltyService;

    /** Solde + tier du membre */
    @GetMapping("/balance/{memberId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER', 'COACH')")
    public ResponseEntity<LoyaltyBalanceDTO> getBalance(@PathVariable Long memberId) {
        return ResponseEntity.ok(loyaltyService.getBalance(memberId));
    }

    /** Historique des transactions (paginé) */
    @GetMapping("/history/{memberId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER', 'COACH')")
    public ResponseEntity<Page<LoyaltyTransactionDTO>> getHistory(
            @PathVariable Long memberId, Pageable pageable) {
        return ResponseEntity.ok(loyaltyService.getHistory(memberId, pageable));
    }

    /** Gagner des points (séance complétée, événement, IA progression…) */
    @PostMapping("/earn")
    @PreAuthorize("hasAnyRole('ADMIN', 'COACH')")
    public ResponseEntity<LoyaltyTransactionDTO> earn(@Valid @RequestBody LoyaltyEarnRequest request) {
        return ResponseEntity.ok(loyaltyService.earnPoints(request));
    }

    /** Utiliser des points (réduction sur abonnement, boutique…) */
    @PostMapping("/redeem")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER')")
    public ResponseEntity<LoyaltyTransactionDTO> redeem(@Valid @RequestBody LoyaltyRedeemRequest request) {
        return ResponseEntity.ok(loyaltyService.redeemPoints(request));
    }

    /** Ajustement manuel par l'admin (bonus, correction…) */
    @PostMapping("/adjust/{memberId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<LoyaltyTransactionDTO> adjust(
            @PathVariable Long memberId,
            @RequestParam Integer points,
            @RequestParam(required = false) String description) {
        return ResponseEntity.ok(loyaltyService.adminAdjust(memberId, points, description));
    }
}
