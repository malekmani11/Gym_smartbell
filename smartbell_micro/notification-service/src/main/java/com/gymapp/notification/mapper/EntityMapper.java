package com.gymapp.notification.mapper;

import com.gymapp.notification.dto.MessageDTO;
import com.gymapp.notification.dto.NotificationDTO;
import com.gymapp.notification.entity.Message;
import com.gymapp.notification.entity.NotificationBroadcast;
import org.springframework.stereotype.Component;

@Component
public class EntityMapper {

    public MessageDTO toMessageDTO(Message message) {
        if (message == null) return null;
        return MessageDTO.builder()
                .id(message.getId())
                .senderId(message.getSender() != null ? message.getSender().getId() : null)
                .senderName(message.getSender() != null
                        ? message.getSender().getFirstName() + " " + message.getSender().getLastName() : null)
                .receiverId(message.getReceiver() != null ? message.getReceiver().getId() : null)
                .receiverName(message.getReceiver() != null
                        ? message.getReceiver().getFirstName() + " " + message.getReceiver().getLastName() : null)
                .content(message.getContent())
                .sentAt(message.getSentAt())
                .isRead(message.getIsRead())
                .build();
    }

    public NotificationDTO toNotificationDTO(NotificationBroadcast broadcast) {
        if (broadcast == null) return null;
        return NotificationDTO.builder()
                .id(broadcast.getId())
                .title(broadcast.getTitle())
                .message(broadcast.getMessage())
                .type(broadcast.getType())
                .targetAll(broadcast.getTargetAll())
                .targetUserId(broadcast.getTargetUserId())
                .targetRole(broadcast.getTargetRole() != null ? broadcast.getTargetRole().name() : null)
                .createdAt(broadcast.getCreatedAt())
                .build();
    }
}
