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
public class EventDTO {

    private Long id;

    @NotBlank(message = "Event title is required")
    private String title;

    private String description;
    private Long createdById;
    private String createdByName;

    @NotNull(message = "Event date is required")
    private LocalDateTime eventDate;

    private LocalDateTime endDate;
    private String location;
    private Integer maxParticipants;
    private String imageUrl;
    private Boolean active;
    private Integer currentRegistrations;
    private LocalDateTime createdAt;
}
