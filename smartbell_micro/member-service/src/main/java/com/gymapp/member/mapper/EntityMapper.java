package com.gymapp.member.mapper;

import com.gymapp.member.dto.MemberDTO;
import com.gymapp.member.dto.SubscriptionDTO;
import com.gymapp.member.dto.SubscriptionPlanDTO;
import com.gymapp.member.dto.UserDTO;
import com.gymapp.member.entity.Member;
import com.gymapp.member.entity.Subscription;
import com.gymapp.member.entity.SubscriptionPlan;
import com.gymapp.member.entity.User;
import org.springframework.stereotype.Component;

import java.util.Comparator;

@Component
public class EntityMapper {

    public UserDTO toUserDTO(User user) {
        if (user == null) return null;
        return UserDTO.builder()
                .id(user.getId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .address(user.getAddress())
                .dateOfBirth(user.getDateOfBirth())
                .gender(user.getGender())
                .profileImageUrl(user.getProfileImageUrl())
                .enabled(user.getEnabled())
                .role(user.getRole() != null ? user.getRole().name() : null)
                .createdAt(user.getCreatedAt())
                .build();
    }

    public MemberDTO toMemberDTO(Member member) {
        if (member == null) return null;

        MemberDTO.MemberDTOBuilder builder = MemberDTO.builder()
                .id(member.getId())
                .userId(member.getId())
                .firstName(member.getFirstName())
                .lastName(member.getLastName())
                .email(member.getEmail())
                .phone(member.getPhone())
                .address(member.getAddress())
                .dateOfBirth(member.getDateOfBirth())
                .gender(member.getGender() != null ? member.getGender().name() : null)
                .profileImageUrl(member.getProfileImageUrl())
                .emergencyContact(member.getEmergencyContact())
                .emergencyPhone(member.getEmergencyPhone())
                .medicalNotes(member.getMedicalNotes())
                .membershipStatus(member.getMembershipStatus())
                .joinDate(member.getJoinDate())
                .loyaltyPoints(member.getLoyaltyPoints())
                .assignedCoachId(member.getAssignedCoachId())
                .messagingEnabled(member.getMessagingEnabled());

        // Abonnement actif le plus récent
        if (member.getSubscriptions() != null) {
            member.getSubscriptions().stream()
                    .filter(s -> s.getStatus() != null)
                    .max(Comparator.comparing(s -> s.getStartDate() != null ? s.getStartDate() : java.time.LocalDate.MIN))
                    .ifPresent(sub -> builder
                            .subscriptionId(sub.getId())
                            .planId(sub.getPlan() != null ? sub.getPlan().getId() : null)
                            .planName(sub.getPlan() != null ? sub.getPlan().getName() : null)
                            .subscriptionStartDate(sub.getStartDate())
                            .subscriptionEndDate(sub.getEndDate())
                            .subscriptionStatus(sub.getStatus()));
        }

        return builder.build();
    }

    public SubscriptionDTO toSubscriptionDTO(Subscription subscription) {
        if (subscription == null) return null;
        return SubscriptionDTO.builder()
                .id(subscription.getId())
                .userId(subscription.getUser() != null ? subscription.getUser().getId() : null)
                .planId(subscription.getPlan() != null ? subscription.getPlan().getId() : null)
                .planName(subscription.getPlan() != null ? subscription.getPlan().getName() : null)
                .startDate(subscription.getStartDate())
                .endDate(subscription.getEndDate())
                .status(subscription.getStatus())
                .createdAt(subscription.getCreatedAt())
                .build();
    }

    public SubscriptionPlanDTO toSubscriptionPlanDTO(SubscriptionPlan plan) {
        if (plan == null) return null;
        return SubscriptionPlanDTO.builder()
                .id(plan.getId())
                .name(plan.getName())
                .description(plan.getDescription())
                .durationMonths(plan.getDurationMonths())
                .price(plan.getPrice())
                .active(plan.getActive())
                .createdAt(plan.getCreatedAt())
                .build();
    }
}
