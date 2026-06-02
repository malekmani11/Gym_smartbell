package com.gymapp.member.entity;

import com.gymapp.member.entity.enums.MembershipStatus;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.time.LocalDate;

@Entity
@Table(name = "members")
@DiscriminatorValue("MEMBER")
@PrimaryKeyJoinColumn(name = "user_id")
@Getter
@Setter
@NoArgsConstructor
@SuperBuilder
public class Member extends User {

    @Enumerated(EnumType.STRING)
    @Column(name = "membership_status", nullable = false)
    @Builder.Default
    private MembershipStatus membershipStatus = MembershipStatus.INACTIVE;

    @Column(name = "join_date")
    private LocalDate joinDate;

    @Column(name = "emergency_contact", length = 100)
    private String emergencyContact;

    @Column(name = "emergency_phone", length = 20)
    private String emergencyPhone;

    @Column(name = "medical_notes", columnDefinition = "TEXT")
    private String medicalNotes;

    @Column(name = "loyalty_points", nullable = false)
    @Builder.Default
    private Integer loyaltyPoints = 0;

    @Column(name = "assigned_coach_id")
    private Long assignedCoachId;

    @Column(name = "messaging_enabled", nullable = false)
    @Builder.Default
    private Boolean messagingEnabled = false;

    // LoyaltyTransaction est dans member-service — relation interne valide
    @OneToMany(mappedBy = "member", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private java.util.Set<LoyaltyTransaction> loyaltyTransactions = new java.util.HashSet<>();
}
