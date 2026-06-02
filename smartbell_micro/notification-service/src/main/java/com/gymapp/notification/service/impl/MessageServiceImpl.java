package com.gymapp.notification.service.impl;

import com.gymapp.notification.dto.MessageDTO;
import com.gymapp.notification.entity.Message;
import com.gymapp.notification.entity.User;
import com.gymapp.notification.mapper.EntityMapper;
import com.gymapp.notification.repository.MessageRepository;
import com.gymapp.notification.repository.UserRepository;
import com.gymapp.notification.service.MessageService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class MessageServiceImpl implements MessageService {

    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final EntityMapper mapper;

    @Override
    public MessageDTO sendMessage(Long senderId, MessageDTO dto) {
        log.info("User {} sending message to user {}", senderId, dto.getReceiverId());
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new EntityNotFoundException("Sender not found"));
        User receiver = userRepository.findById(dto.getReceiverId())
                .orElseThrow(() -> new EntityNotFoundException("Receiver not found"));

        Message message = Message.builder()
                .sender(sender)
                .receiver(receiver)
                .content(dto.getContent())
                .sentAt(LocalDateTime.now())
                .isRead(false)
                .build();

        return mapper.toMessageDTO(messageRepository.save(message));
    }

    @Override
    @Transactional(readOnly = true)
    public List<MessageDTO> getConversation(Long userId1, Long userId2) {
        return messageRepository.findConversation(userId1, userId2).stream()
                .map(mapper::toMessageDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public Page<MessageDTO> getUnreadMessages(Long userId, Pageable pageable) {
        return messageRepository.findByReceiverIdAndIsReadFalse(userId, pageable).map(mapper::toMessageDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Long getUnreadCount(Long userId) {
        return messageRepository.countByReceiverIdAndIsReadFalse(userId);
    }

    @Override
    public void markAsRead(Long messageId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new EntityNotFoundException("Message not found"));
        message.setIsRead(true);
        messageRepository.save(message);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Long> getConversationPartners(Long userId) {
        return messageRepository.findConversationPartnerIds(userId);
    }
}
