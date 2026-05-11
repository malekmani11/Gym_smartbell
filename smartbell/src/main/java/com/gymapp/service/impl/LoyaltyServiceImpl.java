package com.gymapp.service.impl;

import com.gymapp.dto.LoyaltyBalanceDTO;
import com.gymapp.dto.LoyaltyEarnRequest;
import com.gymapp.dto.LoyaltyRedeemRequest;
import com.gymapp.dto.LoyaltyTransactionDTO;
import com.gymapp.entity.LoyaltyTransaction;
import com.gymapp.entity.Member;
import com.gymapp.entity.enums.LoyaltyTransactionType;
import com.gymapp.repository.LoyaltyTransactionRepository;
import com.gymapp.repository.MemberRepository;
import com.gymapp.service.LoyaltyService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class LoyaltyServiceImpl implements LoyaltyService {

    private final LoyaltyTransactionRepository loyaltyRepo;
    private final MemberRepository memberRepo;

    // Seuils des tiers (points cumulés)
    private static final int SILVER_THRESHOLD   = 500;
    private static final int GOLD_THRESHOLD     = 1500;
    private static final int PLATINUM_THRESHOLD = 3000;

    @Override
    public LoyaltyBalanceDTO getBalance(Long memberId) {
        Member member = findMember(memberId);
        int points = member.getLoyaltyPoints();
        return LoyaltyBalanceDTO.builder()
                .memberId(memberId)
                .firstName(member.getFirstName())
                .lastName(member.getLastName())
                .loyaltyPoints(points)
                .tier(resolveTier(points))
                .nextTierPoints(nextTierGap(points))
                .build();
    }

    @Override
    @Transactional
    public LoyaltyTransactionDTO earnPoints(LoyaltyEarnRequest request) {
        Member member = findMember(request.getMemberId());
        member.setLoyaltyPoints(member.getLoyaltyPoints() + request.getPoints());
        memberRepo.save(member);

        LoyaltyTransaction tx = LoyaltyTransaction.builder()
                .member(member)
                .type(LoyaltyTransactionType.EARN)
                .points(request.getPoints())
                .description(request.getDescription())
                .build();
        loyaltyRepo.save(tx);

        log.info("Loyalty EARN — membre={} points=+{} solde={}", memberId(member), request.getPoints(), member.getLoyaltyPoints());
        return toDTO(tx);
    }

    @Override
    @Transactional
    public LoyaltyTransactionDTO redeemPoints(LoyaltyRedeemRequest request) {
        Member member = findMember(request.getMemberId());
        if (member.getLoyaltyPoints() < request.getPoints()) {
            throw new IllegalStateException("Solde insuffisant : " + member.getLoyaltyPoints() + " points disponibles");
        }
        member.setLoyaltyPoints(member.getLoyaltyPoints() - request.getPoints());
        memberRepo.save(member);

        LoyaltyTransaction tx = LoyaltyTransaction.builder()
                .member(member)
                .type(LoyaltyTransactionType.REDEEM)
                .points(request.getPoints())
                .description("Utilisation de " + request.getPoints() + " points de fidélité")
                .build();
        loyaltyRepo.save(tx);

        log.info("Loyalty REDEEM — membre={} points=-{} solde={}", memberId(member), request.getPoints(), member.getLoyaltyPoints());
        return toDTO(tx);
    }

    @Override
    @Transactional
    public LoyaltyTransactionDTO adminAdjust(Long memberId, Integer points, String description) {
        Member member = findMember(memberId);
        int newBalance = member.getLoyaltyPoints() + points;
        if (newBalance < 0) {
            throw new IllegalStateException("L'ajustement rendrait le solde négatif");
        }
        member.setLoyaltyPoints(newBalance);
        memberRepo.save(member);

        LoyaltyTransaction tx = LoyaltyTransaction.builder()
                .member(member)
                .type(LoyaltyTransactionType.ADMIN_ADJUST)
                .points(points)
                .description(description != null ? description : "Ajustement administrateur")
                .build();
        loyaltyRepo.save(tx);

        log.info("Loyalty ADMIN_ADJUST — membre={} delta={} solde={}", memberId, points, newBalance);
        return toDTO(tx);
    }

    @Override
    public Page<LoyaltyTransactionDTO> getHistory(Long memberId, Pageable pageable) {
        findMember(memberId); // validation
        return loyaltyRepo.findByMemberIdOrderByCreatedAtDesc(memberId, pageable).map(this::toDTO);
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private Member findMember(Long memberId) {
        return memberRepo.findById(memberId)
                .orElseThrow(() -> new IllegalArgumentException("Membre introuvable : " + memberId));
    }

    private String resolveTier(int points) {
        if (points >= PLATINUM_THRESHOLD) return "PLATINUM";
        if (points >= GOLD_THRESHOLD)     return "GOLD";
        if (points >= SILVER_THRESHOLD)   return "SILVER";
        return "BRONZE";
    }

    private Integer nextTierGap(int points) {
        if (points >= PLATINUM_THRESHOLD) return 0;
        if (points >= GOLD_THRESHOLD)     return PLATINUM_THRESHOLD - points;
        if (points >= SILVER_THRESHOLD)   return GOLD_THRESHOLD - points;
        return SILVER_THRESHOLD - points;
    }

    private LoyaltyTransactionDTO toDTO(LoyaltyTransaction tx) {
        return LoyaltyTransactionDTO.builder()
                .id(tx.getId())
                .memberId(tx.getMember().getId())
                .type(tx.getType())
                .points(tx.getPoints())
                .description(tx.getDescription())
                .createdAt(tx.getCreatedAt())
                .build();
    }

    private Long memberId(Member m) { return m.getId(); }
}
