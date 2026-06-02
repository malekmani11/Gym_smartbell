package com.gymapp.notification.controller;

import com.gymapp.notification.dto.GroupMessageDTO;
import com.gymapp.notification.entity.GroupMessage;
import com.gymapp.notification.repository.GroupMessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/messages/group")
@RequiredArgsConstructor
public class GroupMessageController {

    private final GroupMessageRepository repo;

    @GetMapping
    public ResponseEntity<List<GroupMessageDTO>> getAll() {
        List<GroupMessageDTO> messages = repo.findAllByOrderBySentAtAsc()
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(messages);
    }

    @PostMapping
    public ResponseEntity<GroupMessageDTO> send(@RequestBody GroupMessageDTO dto) {
        GroupMessage msg = GroupMessage.builder()
                .senderId(dto.getSenderId())
                .senderName(dto.getSenderName())
                .senderRole(dto.getSenderRole())
                .content(dto.getContent())
                .sentAt(LocalDateTime.now())
                .build();
        return ResponseEntity.status(HttpStatus.CREATED).body(toDTO(repo.save(msg)));
    }

    private GroupMessageDTO toDTO(GroupMessage m) {
        return GroupMessageDTO.builder()
                .id(m.getId())
                .senderId(m.getSenderId())
                .senderName(m.getSenderName())
                .senderRole(m.getSenderRole())
                .content(m.getContent())
                .sentAt(m.getSentAt())
                .build();
    }
}
