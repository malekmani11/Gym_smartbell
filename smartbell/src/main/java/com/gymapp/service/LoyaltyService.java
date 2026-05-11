package com.gymapp.service;

import com.gymapp.dto.LoyaltyBalanceDTO;
import com.gymapp.dto.LoyaltyEarnRequest;
import com.gymapp.dto.LoyaltyRedeemRequest;
import com.gymapp.dto.LoyaltyTransactionDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface LoyaltyService {

    LoyaltyBalanceDTO getBalance(Long memberId);

    LoyaltyTransactionDTO earnPoints(LoyaltyEarnRequest request);

    LoyaltyTransactionDTO redeemPoints(LoyaltyRedeemRequest request);

    LoyaltyTransactionDTO adminAdjust(Long memberId, Integer points, String description);

    Page<LoyaltyTransactionDTO> getHistory(Long memberId, Pageable pageable);
}
