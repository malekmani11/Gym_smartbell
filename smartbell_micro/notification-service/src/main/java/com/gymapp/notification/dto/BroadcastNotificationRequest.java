package com.gymapp.notification.dto;

import com.gymapp.notification.entity.enums.NotificationType;
import lombok.Data;

@Data
public class BroadcastNotificationRequest {
    private String title;
    private String message;
    private NotificationType type;
    private Boolean targetAll;
    private Long userId;
    private String roleName;
}
