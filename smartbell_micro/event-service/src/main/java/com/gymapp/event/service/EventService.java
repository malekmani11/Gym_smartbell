package com.gymapp.event.service;

import com.gymapp.event.dto.EventDTO;
import com.gymapp.event.dto.EventRegistrationDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

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

    // ── Nouveaux endpoints ──────────────────────────────────────────────────────

    List<EventRegistrationDTO> getEventRegistrations(Long eventId);

    EventRegistrationDTO registerByEmail(Long eventId, String email);

    void unregisterByEmail(Long eventId, String email);

    List<EventRegistrationDTO> getMyRegistrationsByEmail(String email);
}
