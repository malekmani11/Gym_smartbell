package com.gymapp.controller;

import com.gymapp.dto.BroadcastNotificationRequest;
import com.gymapp.dto.NotificationDTO;
import com.gymapp.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    // ── Admin ────────────────────────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<List<NotificationDTO>> getAllNotifications() {
        return ResponseEntity.ok(notificationService.getAllNotifications());
    }

    @PostMapping
    public ResponseEntity<List<NotificationDTO>> broadcast(@RequestBody BroadcastNotificationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(notificationService.broadcast(request));
    }

    @GetMapping("/unread/count")
    public ResponseEntity<Long> getAdminUnreadCount() {
        return ResponseEntity.ok(notificationService.countAllUnreadByAdmin());
    }

    @PatchMapping("/{broadcastId}/read")
    public ResponseEntity<Void> markAsReadByAdmin(@PathVariable Long broadcastId) {
        notificationService.markAsReadByAdmin(broadcastId);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/mark-all-read")
    public ResponseEntity<Void> markAllAsReadByAdmin() {
        notificationService.markAllAsReadByAdmin();
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{broadcastId}")
    public ResponseEntity<Void> deleteNotification(@PathVariable Long broadcastId) {
        notificationService.deleteNotification(broadcastId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping
    public ResponseEntity<Void> deleteAllNotifications() {
        notificationService.deleteAllNotifications();
        return ResponseEntity.noContent().build();
    }

    // ── Membre / Coach (mobile) ───────────────────────────────────────────────

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<NotificationDTO>> getNotificationsForUser(@PathVariable Long userId) {
        return ResponseEntity.ok(notificationService.getNotificationsForUser(userId));
    }

    @PatchMapping("/{broadcastId}/read/user/{userId}")
    public ResponseEntity<Void> markAsReadByUser(@PathVariable Long broadcastId,
                                                  @PathVariable Long userId) {
        notificationService.markAsReadByUser(broadcastId, userId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/user/{userId}/unread/count")
    public ResponseEntity<Long> getUnreadCountForUser(@PathVariable Long userId) {
        return ResponseEntity.ok(notificationService.countUnreadForUser(userId));
    }
}
