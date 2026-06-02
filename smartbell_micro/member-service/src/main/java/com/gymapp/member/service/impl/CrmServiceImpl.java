package com.gymapp.member.service.impl;

import com.gymapp.member.dto.CrmMemberDTO;
import com.gymapp.member.entity.Member;
import com.gymapp.member.entity.Subscription;
import com.gymapp.member.entity.enums.MembershipStatus;
import com.gymapp.member.entity.enums.SubscriptionStatus;
import com.gymapp.member.repository.MemberRepository;
import com.gymapp.member.repository.SubscriptionRepository;
import com.gymapp.member.service.CrmService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class CrmServiceImpl implements CrmService {

    private final MemberRepository memberRepository;
    private final SubscriptionRepository subscriptionRepository;

    @Override
    public Map<String, List<CrmMemberDTO>> getPipeline() {
        List<Member> members = memberRepository.findAll();

        Map<String, List<CrmMemberDTO>> pipeline = new LinkedHashMap<>();
        pipeline.put("PROSPECT", new ArrayList<>());
        pipeline.put("ACTIVE",   new ArrayList<>());
        pipeline.put("AT_RISK",  new ArrayList<>());
        pipeline.put("CHURNED",  new ArrayList<>());

        for (Member member : members) {
            CrmMemberDTO dto = toDTO(member);
            String stage = resolveCrmStage(member, dto.getDaysUntilExpiry());
            dto.setCrmStage(stage);
            pipeline.get(stage).add(dto);
        }

        return pipeline;
    }

    @Override
    @Transactional
    public CrmMemberDTO updateStage(Long memberId, String stage) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("Member not found: " + memberId));

        // Map CRM stage to membership status using the actual enum values
        MembershipStatus newStatus = switch (stage) {
            case "ACTIVE"  -> MembershipStatus.ACTIVE;
            case "AT_RISK" -> MembershipStatus.ACTIVE;   // stays ACTIVE, flagged by expiry
            case "CHURNED" -> MembershipStatus.SUSPENDED;
            default        -> MembershipStatus.INACTIVE;
        };
        member.setMembershipStatus(newStatus);
        memberRepository.save(member);

        CrmMemberDTO dto = toDTO(member);
        dto.setCrmStage(stage);
        return dto;
    }

    @Override
    @Transactional
    public CrmMemberDTO addNote(Long memberId, String note) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("Member not found: " + memberId));

        String existing = member.getMedicalNotes() != null ? member.getMedicalNotes() : "";
        String timestamp = LocalDate.now().toString();
        member.setMedicalNotes(existing + "\n[" + timestamp + "] " + note);
        memberRepository.save(member);

        CrmMemberDTO dto = toDTO(member);
        dto.setNotes(member.getMedicalNotes());
        return dto;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private CrmMemberDTO toDTO(Member member) {
        String firstName = member.getFirstName() != null ? member.getFirstName() : "";
        String lastName  = member.getLastName()  != null ? member.getLastName()  : "";
        String email     = member.getEmail()     != null ? member.getEmail()     : "";

        LocalDate expiryDate = null;
        String membershipType = "Standard";

        try {
            Long userId = member.getId();
            if (userId != null) {
                List<Subscription> subs = subscriptionRepository
                        .findByUserId(userId, PageRequest.of(0, 50))
                        .getContent();

                Optional<Subscription> latest = subs.stream()
                        .max(Comparator.comparing(Subscription::getEndDate,
                                Comparator.nullsLast(Comparator.naturalOrder())));

                if (latest.isPresent()) {
                    expiryDate     = latest.get().getEndDate();
                    membershipType = latest.get().getPlan() != null
                            ? latest.get().getPlan().getName() : "Standard";
                }
            }
        } catch (Exception ignored) { /* subscription data optional */ }

        Integer daysUntilExpiry = null;
        if (expiryDate != null) {
            daysUntilExpiry = (int) ChronoUnit.DAYS.between(LocalDate.now(), expiryDate);
        }

        return CrmMemberDTO.builder()
                .memberId(member.getId())
                .userId(member.getId())
                .firstName(firstName)
                .lastName(lastName)
                .email(email)
                .phone(member.getEmergencyPhone())
                .membershipType(membershipType)
                .membershipStatus(member.getMembershipStatus())
                .joinDate(member.getJoinDate())
                .expiryDate(expiryDate)
                .daysUntilExpiry(daysUntilExpiry)
                .notes(member.getMedicalNotes())
                .build();
    }

    private String resolveCrmStage(Member member, Integer daysUntilExpiry) {
        MembershipStatus status = member.getMembershipStatus();
        if (status == MembershipStatus.INACTIVE)  return "PROSPECT";
        if (status == MembershipStatus.SUSPENDED) return "CHURNED";
        // ACTIVE — check subscription expiry proximity
        if (daysUntilExpiry != null && daysUntilExpiry < 14) return "AT_RISK";
        return "ACTIVE";
    }
}
