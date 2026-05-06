package com.gymapp.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MessageDTO {

    private Long id;

    @NotNull(message = "Receiver ID is required")
    private Long receiverId;

    private Long senderId;
    private String senderName;
    private String receiverName;

    @NotBlank(message = "Message content is required")
    private String content;

    private LocalDateTime sentAt;
    private Boolean isRead;
}
