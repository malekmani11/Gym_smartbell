package com.gymapp.event.mapper;

import com.gymapp.event.dto.EventDTO;
import com.gymapp.event.dto.EventRegistrationDTO;
import com.gymapp.event.entity.Event;
import com.gymapp.event.entity.EventRegistration;
import org.springframework.stereotype.Component;

@Component
public class EntityMapper {

    public EventDTO toEventDTO(Event event) {
        if (event == null) return null;
        return EventDTO.builder()
                .id(event.getId())
                .title(event.getTitle())
                .description(event.getDescription())
                .createdById(event.getCreatedBy() != null ? event.getCreatedBy().getId() : null)
                .createdByName(event.getCreatedBy() != null
                        ? event.getCreatedBy().getFirstName() + " " + event.getCreatedBy().getLastName() : null)
                .eventDate(event.getEventDate())
                .endDate(event.getEndDate())
                .location(event.getLocation())
                .maxParticipants(event.getMaxParticipants())
                .imageUrl(event.getImageUrl())
                .active(event.getActive())
                .registrationCount(event.getRegistrations() != null ? event.getRegistrations().size() : 0)
                .currentRegistrations(event.getRegistrations() != null ? event.getRegistrations().size() : 0)
                .createdAt(event.getCreatedAt())
                .build();
    }

    public EventRegistrationDTO toEventRegistrationDTO(EventRegistration registration) {
        if (registration == null) return null;
        return EventRegistrationDTO.builder()
                .id(registration.getId())
                .eventId(registration.getEvent() != null ? registration.getEvent().getId() : null)
                .eventTitle(registration.getEvent() != null ? registration.getEvent().getTitle() : null)
                .userId(registration.getUser() != null ? registration.getUser().getId() : null)
                .userName(registration.getUser() != null
                        ? registration.getUser().getFirstName() + " " + registration.getUser().getLastName() : null)
                .registrationDate(registration.getRegistrationDate())
                .status(registration.getStatus())
                .build();
    }
}
