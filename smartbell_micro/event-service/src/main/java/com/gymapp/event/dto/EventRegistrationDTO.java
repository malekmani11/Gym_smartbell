package com.gymapp.event.dto;

import com.gymapp.event.entity.enums.RegistrationStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventRegistrationDTO {

    private Long id;
    private Long eventId;
    private String eventTitle;
    private Long userId;
    private String userName;
    private String firstName;
    private String lastName;
    private String email;
    private String profileImageUrl;
    private LocalDateTime registrationDate;
    private RegistrationStatus status;
}
