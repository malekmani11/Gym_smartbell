package com.gymapp.dto;

import com.gymapp.entity.enums.MembershipStatus;
import com.gymapp.entity.enums.SubscriptionStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MemberDTO {

    // ── Identity ──────────────────────────────────────────
    private Long id;
    private Long userId;
    private String firstName;
    private String lastName;
    private String email;
    private String password;          // creation only — not returned by GET
    private String phone;
    private String address;
    private LocalDate dateOfBirth;
    private String gender;
    private String emergencyContact;
    private String emergencyPhone;
    private String medicalNotes;
    private MembershipStatus membershipStatus;
    private LocalDate joinDate;
    private String profileImageUrl;
    private Integer loyaltyPoints;

    // ── Active subscription ────────────────────────────────
    private Long   subscriptionId;
    private String planName;
    private Long   planId;
    private LocalDate subscriptionStartDate;
    private LocalDate subscriptionEndDate;
    private SubscriptionStatus subscriptionStatus;

    // ── Last payment ────────────────────────────────────────
    private String lastPaymentStatus;   // COMPLETED / PENDING / FAILED
    private String lastPaymentMethod;   // CARTE / CASH / VIREMENT
    private BigDecimal lastPaymentAmount;
}
