package com.gymapp.service;

import com.gymapp.dto.MessageDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface MessageService {

    MessageDTO sendMessage(Long senderId, MessageDTO dto);

    List<MessageDTO> getConversation(Long userId1, Long userId2);

    Page<MessageDTO> getUnreadMessages(Long userId, Pageable pageable);

    Long getUnreadCount(Long userId);

    void markAsRead(Long messageId);

    List<Long> getConversationPartners(Long userId);
}
