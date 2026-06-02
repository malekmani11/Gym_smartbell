package com.gymapp.event.dto;

import jakarta.validation.constraints.Future;
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

    @NotNull(message = "La date de début est obligatoire")
    @Future(message = "La date de début doit être dans le futur")
    private LocalDateTime eventDate;

    private LocalDateTime endDate;
    private String location;
    private Integer maxParticipants;
    private String imageUrl;
    private Boolean active;
    private Integer currentRegistrations;
    private Integer registrationCount;
    private LocalDateTime createdAt;
}
