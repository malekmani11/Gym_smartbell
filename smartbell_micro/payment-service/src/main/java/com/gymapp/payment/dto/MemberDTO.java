package com.gymapp.payment.dto;

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

    private Long id;
    private Long userId;
    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private String address;
    private LocalDate dateOfBirth;
    private String gender;
    private String emergencyContact;
    private String emergencyPhone;
    private String medicalNotes;
    private String membershipStatus;    // String — enum défini dans member-service
    private LocalDate joinDate;
    private String profileImageUrl;
    private Integer loyaltyPoints;

    private Long   subscriptionId;
    private String planName;
    private Long   planId;
    private LocalDate subscriptionStartDate;
    private LocalDate subscriptionEndDate;
    private String subscriptionStatus;  // String — enum défini dans member-service

    private String lastPaymentStatus;
    private String lastPaymentMethod;
    private BigDecimal lastPaymentAmount;
}
