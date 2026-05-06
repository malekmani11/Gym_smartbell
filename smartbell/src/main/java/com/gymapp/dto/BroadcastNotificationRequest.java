package com.gymapp.dto;

import com.gymapp.entity.enums.NotificationType;
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
