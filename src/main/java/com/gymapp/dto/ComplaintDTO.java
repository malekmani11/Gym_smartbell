package com.gymapp.dto;

import com.gymapp.entity.enums.ComplaintStatus;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ComplaintDTO {

    private Long id;
    private Long userId;
    private String userName;
    private String firstName;
    private String lastName;

    @NotBlank(message = "Subject is required")
    private String subject;

    @NotBlank(message = "Description is required")
    private String description;

    private ComplaintStatus status;
    private String response;
    private LocalDateTime createdAt;
    private LocalDateTime resolvedAt;
}
