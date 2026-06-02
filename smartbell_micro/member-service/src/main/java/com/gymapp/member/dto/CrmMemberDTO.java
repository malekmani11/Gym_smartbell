package com.gymapp.member.dto;

import com.gymapp.member.entity.enums.MembershipStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CrmMemberDTO {

    private Long memberId;
    private Long userId;
    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private String membershipType;
    private MembershipStatus membershipStatus;
    private String crmStage;   // PROSPECT, ACTIVE, AT_RISK, CHURNED
    private LocalDate joinDate;
    private LocalDate expiryDate;
    private Integer daysUntilExpiry;
    private String lastVisit;
    private String notes;
}
