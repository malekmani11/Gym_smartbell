package com.gymapp.service;

import com.gymapp.dto.NotificationDTO;
import com.gymapp.entity.enums.NotificationType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface NotificationService {

    NotificationDTO createNotification(Long userId, String title, String message, NotificationType type);

    Page<NotificationDTO> getNotifications(Long userId, Pageable pageable);

    Page<NotificationDTO> getUnreadNotifications(Long userId, Pageable pageable);

    Long getUnreadCount(Long userId);

    void markAsRead(Long notificationId);

    void markAllAsRead(Long userId);
}
