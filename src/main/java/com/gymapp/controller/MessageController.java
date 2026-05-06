package com.gymapp.controller;

import com.gymapp.dto.MessageDTO;
import com.gymapp.service.MessageService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/messages")
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    @PostMapping("/sender/{senderId}")
    public ResponseEntity<MessageDTO> sendMessage(
            @PathVariable Long senderId, @RequestBody MessageDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(messageService.sendMessage(senderId, dto));
    }

    @GetMapping("/conversation/{userId1}/{userId2}")
    public ResponseEntity<List<MessageDTO>> getConversation(
            @PathVariable Long userId1, @PathVariable Long userId2) {
        return ResponseEntity.ok(messageService.getConversation(userId1, userId2));
    }

    @GetMapping("/user/{userId}/unread")
    public ResponseEntity<Page<MessageDTO>> getUnreadMessages(
            @PathVariable Long userId, Pageable pageable) {
        return ResponseEntity.ok(messageService.getUnreadMessages(userId, pageable));
    }

    @GetMapping("/user/{userId}/unread/count")
    public ResponseEntity<Long> getUnreadCount(@PathVariable Long userId) {
        return ResponseEntity.ok(messageService.getUnreadCount(userId));
    }

    @PatchMapping("/{messageId}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable Long messageId) {
        messageService.markAsRead(messageId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/user/{userId}/partners")
    public ResponseEntity<List<Long>> getConversationPartners(@PathVariable Long userId) {
        return ResponseEntity.ok(messageService.getConversationPartners(userId));
    }
}
