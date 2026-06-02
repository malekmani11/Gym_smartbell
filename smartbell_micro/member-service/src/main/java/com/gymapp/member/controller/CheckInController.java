package com.gymapp.member.controller;

import com.gymapp.member.dto.CheckInDTO;
import com.gymapp.member.dto.LoyaltyEarnRequest;
import com.gymapp.member.entity.CheckIn;
import com.gymapp.member.entity.Member;
import com.gymapp.member.entity.Subscription;
import com.gymapp.member.entity.enums.MembershipStatus;
import com.gymapp.member.entity.enums.SubscriptionStatus;
import com.gymapp.member.repository.CheckInRepository;
import com.gymapp.member.repository.MemberRepository;
import com.gymapp.member.repository.SubscriptionRepository;
import com.gymapp.member.security.CustomUserDetails;
import com.gymapp.member.service.LoyaltyService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/checkins")
@RequiredArgsConstructor
public class CheckInController {

    private static final String VALID_QR      = "smartbell-checkin";
    private static final int    POINTS_EARNED = 10;

    private final CheckInRepository     checkInRepository;
    private final MemberRepository      memberRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final LoyaltyService        loyaltyService;

    /**
     * Member scans the entrance QR code → records check-in + awards loyalty points.
     * Called with { "qrCode": "smartbell-checkin" }
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER')")
    public ResponseEntity<?> scan(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal CustomUserDetails principal) {

        final String qrCode = body.getOrDefault("qrCode", "");

        if (!VALID_QR.equalsIgnoreCase(qrCode)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "QR code invalide"));
        }

        Long userId = principal.getUser().getId();
        Member member = memberRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("Member not found for user: " + userId));

        boolean isActive  = member.getMembershipStatus() == MembershipStatus.ACTIVE;
        String  status    = isActive ? "SUCCESS" : "FAILED";
        String  note      = isActive ? "Entrée validée" : "Abonnement inactif";
        int     points    = 0;

        // Find active subscription for expiry info
        String  subStatus  = "INACTIVE";
        String  expiryDate = null;
        List<Subscription> activeSubs = subscriptionRepository
                .findByUserIdAndStatus(userId, SubscriptionStatus.ACTIVE);
        if (!activeSubs.isEmpty()) {
            Subscription latest = activeSubs.get(activeSubs.size() - 1);
            subStatus  = latest.getStatus().name();
            expiryDate = latest.getEndDate().toString();
        }

        // Award points for successful check-in
        if (isActive) {
            try {
                LoyaltyEarnRequest earn = new LoyaltyEarnRequest();
                earn.setMemberId(member.getId());
                earn.setPoints(POINTS_EARNED);
                earn.setDescription("Check-in salle de sport");
                loyaltyService.earnPoints(earn);
                points = POINTS_EARNED;
            } catch (Exception ignored) {}
        }

        CheckIn saved = checkInRepository.save(CheckIn.builder()
                .member(member)
                .checkInTime(LocalDateTime.now())
                .status(status)
                .pointsAwarded(points)
                .note(note)
                .build());

        CheckInDTO dto = toDTO(saved);
        dto.setSubscriptionStatus(subStatus);
        dto.setExpiryDate(expiryDate);

        return ResponseEntity
                .status(isActive ? HttpStatus.CREATED : HttpStatus.FORBIDDEN)
                .body(dto);
    }

    /** Get check-in history for a member. */
    @GetMapping("/member/{memberId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER', 'COACH')")
    public ResponseEntity<List<CheckInDTO>> getHistory(@PathVariable Long memberId) {
        return ResponseEntity.ok(
                checkInRepository.findByMemberIdOrderByCheckInTimeDesc(memberId)
                        .stream()
                        .map(this::toDTO)
                        .collect(Collectors.toList())
        );
    }

    private CheckInDTO toDTO(CheckIn c) {
        return CheckInDTO.builder()
                .id(c.getId())
                .memberId(c.getMember().getId())
                .memberName(c.getMember().getFirstName() + " " + c.getMember().getLastName())
                .checkInTime(c.getCheckInTime())
                .status(c.getStatus())
                .pointsAwarded(c.getPointsAwarded())
                .note(c.getNote())
                .build();
    }
}
