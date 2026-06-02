package com.gymapp.notification.dto;

import com.gymapp.notification.entity.enums.NotificationType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDTO {

    private Long id;
    private String title;
    private String message;
    private NotificationType type;
    private Boolean isRead;
    private LocalDateTime createdAt;

    /** Informations de ciblage (admin uniquement) */
    private Boolean targetAll;
    private String targetRole;
    private Long targetUserId;
}
