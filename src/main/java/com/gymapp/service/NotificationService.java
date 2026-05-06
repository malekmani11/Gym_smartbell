package com.gymapp.service;

import com.gymapp.dto.BroadcastNotificationRequest;
import com.gymapp.dto.NotificationDTO;

import java.util.List;

public interface NotificationService {

    // ── Admin (panel de gestion) ──────────────────────────────────────────────

    List<NotificationDTO> getAllNotifications();

    List<NotificationDTO> broadcast(BroadcastNotificationRequest request);

    void markAsReadByAdmin(Long broadcastId);

    void markAllAsReadByAdmin();

    long countAllUnreadByAdmin();

    void deleteNotification(Long broadcastId);

    void deleteAllNotifications();

    // ── Membre / Coach (mobile & self-service) ────────────────────────────────

    List<NotificationDTO> getNotificationsForUser(Long userId);

    void markAsReadByUser(Long broadcastId, Long userId);

    long countUnreadForUser(Long userId);
}
