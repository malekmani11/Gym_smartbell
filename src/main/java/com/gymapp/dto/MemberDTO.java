package com.gymapp.dto;

import com.gymapp.entity.enums.MembershipStatus;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

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
    private String emergencyContact;
    private String emergencyPhone;
    private String medicalNotes;
    private MembershipStatus membershipStatus;
    private LocalDate joinDate;
}
