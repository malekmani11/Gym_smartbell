package com.gymapp.service;

import com.gymapp.dto.EventDTO;
import com.gymapp.dto.EventRegistrationDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface EventService {

    EventDTO createEvent(EventDTO dto, Long creatorId);

    EventDTO getEventById(Long id);

    Page<EventDTO> getActiveEvents(Pageable pageable);

    Page<EventDTO> getEventsByCreator(Long userId, Pageable pageable);

    EventDTO updateEvent(Long id, EventDTO dto);

    void deleteEvent(Long id);

    EventRegistrationDTO registerForEvent(Long eventId, Long userId);

    EventRegistrationDTO cancelRegistration(Long registrationId);

    Page<EventRegistrationDTO> getRegistrationsByUser(Long userId, Pageable pageable);
}
