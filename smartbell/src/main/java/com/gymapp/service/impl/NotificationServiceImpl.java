package com.gymapp.service.impl;

import com.gymapp.dto.BroadcastNotificationRequest;
import com.gymapp.dto.NotificationDTO;
import com.gymapp.entity.NotificationBroadcast;
import com.gymapp.entity.NotificationRead;
import com.gymapp.entity.Role;
import com.gymapp.entity.User;
import com.gymapp.entity.enums.NotificationType;
import com.gymapp.repository.NotificationBroadcastRepository;
import com.gymapp.repository.NotificationReadRepository;
import com.gymapp.repository.UserRepository;
import com.gymapp.service.FcmService;
import com.gymapp.service.NotificationService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class NotificationServiceImpl implements NotificationService {

    private final NotificationBroadcastRepository broadcastRepo;
    private final NotificationReadRepository readRepo;
    private final UserRepository userRepository;
    private final FcmService fcmService;

    // ── Admin ─────────────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<NotificationDTO> getAllNotifications() {
        return broadcastRepo.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(b -> toDTO(b, Boolean.TRUE.equals(b.getIsReadByAdmin())))
                .collect(Collectors.toList());
    }

    @Override
    public List<NotificationDTO> broadcast(BroadcastNotificationRequest req) {
        NotificationType type = req.getType() != null ? req.getType() : NotificationType.INFO;

        Role targetRole = null;
        if (req.getRoleName() != null && !req.getRoleName().isBlank()) {
            try { targetRole = Role.valueOf(req.getRoleName()); } catch (IllegalArgumentException ignored) {}
        }

        NotificationBroadcast broadcast = NotificationBroadcast.builder()
                .title(req.getTitle())
                .message(req.getMessage())
                .type(type)
                .targetAll(Boolean.TRUE.equals(req.getTargetAll()))
                .targetRole(targetRole)
                .targetUserId(req.getUserId())
                .build();

        NotificationBroadcast saved = broadcastRepo.save(broadcast);
        log.info("Broadcast created id={} targetAll={} role={} userId={}",
                saved.getId(), saved.getTargetAll(), saved.getTargetRole(), saved.getTargetUserId());

        // ── Envoi FCM push notification ──────────────────────────────────────
        String title = req.getTitle();
        String msg   = req.getMessage();
        if (Boolean.TRUE.equals(req.getTargetAll())) {
            fcmService.sendToAll(title, msg);
        } else if (targetRole != null) {
            fcmService.sendToRole(targetRole, title, msg);
        } else if (req.getUserId() != null) {
            fcmService.sendToUser(req.getUserId(), title, msg);
        }

        return List.of(toDTO(saved, false));
    }

    @Override
    public void markAsReadByAdmin(Long broadcastId) {
        if (broadcastId == null) return;
        broadcastRepo.findById(broadcastId).ifPresent(b -> {
            b.setIsReadByAdmin(true);
            broadcastRepo.save(b);
        });
    }

    @Override
    public void markAllAsReadByAdmin() {
        broadcastRepo.markAllAsReadByAdmin();
    }

    @Override
    @Transactional(readOnly = true)
    public long countAllUnreadByAdmin() {
        return broadcastRepo.countByIsReadByAdminFalse();
    }

    @Override
    public void deleteNotification(Long broadcastId) {
        if (broadcastId == null) return;
        readRepo.deleteAllByBroadcastId(broadcastId);
        broadcastRepo.deleteById(broadcastId);
    }

    @Override
    public void deleteAllNotifications() {
        readRepo.deleteAll();
        broadcastRepo.deleteAll();
    }

    // ── Membre / Coach ────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<NotificationDTO> getNotificationsForUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found: " + userId));

        long uid = userId;
        List<NotificationBroadcast> broadcasts = broadcastRepo.findForUser(user.getRole(), uid);
        Set<Long> readIds = readRepo.findReadBroadcastIdsByUserId(uid);

        return broadcasts.stream()
                .map(b -> toDTO(b, readIds.contains(b.getId())))
                .collect(Collectors.toList());
    }

    @Override
    public void markAsReadByUser(Long broadcastId, Long userId) {
        if (broadcastId == null || userId == null) return;
        if (readRepo.existsByBroadcastIdAndUserId(broadcastId, userId)) return;

        NotificationBroadcast broadcast = broadcastRepo.findById(broadcastId)
                .orElseThrow(() -> new EntityNotFoundException("Broadcast not found: " + broadcastId));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found: " + userId));

        NotificationRead read = new NotificationRead();
        read.setBroadcast(broadcast);
        read.setUser(user);
        readRepo.save(read);
    }

    @Override
    @Transactional(readOnly = true)
    public long countUnreadForUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found: " + userId));
        long uid = userId;
        return readRepo.countUnreadForUser(user.getRole(), uid);
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private NotificationDTO toDTO(NotificationBroadcast b, boolean isRead) {
        return NotificationDTO.builder()
                .id(b.getId())
                .title(b.getTitle())
                .message(b.getMessage())
                .type(b.getType())
                .isRead(isRead)
                .createdAt(b.getCreatedAt())
                .targetAll(b.getTargetAll())
                .targetRole(b.getTargetRole() != null ? b.getTargetRole().name() : null)
                .targetUserId(b.getTargetUserId())
                .build();
    }
}
