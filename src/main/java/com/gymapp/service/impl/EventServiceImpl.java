package com.gymapp.service.impl;

import com.gymapp.dto.EventDTO;
import com.gymapp.dto.EventRegistrationDTO;
import com.gymapp.entity.*;
import com.gymapp.entity.enums.RegistrationStatus;
import com.gymapp.mapper.EntityMapper;
import com.gymapp.repository.*;
import com.gymapp.service.EventService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class EventServiceImpl implements EventService {

    private final EventRepository eventRepository;
    private final EventRegistrationRepository registrationRepository;
    private final UserRepository userRepository;
    private final EntityMapper mapper;

    @Override
    public EventDTO createEvent(EventDTO dto, Long creatorId) {
        log.info("Creating event: {}", dto.getTitle());
        User creator = userRepository.findById(creatorId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        Event event = Event.builder()
                .title(dto.getTitle())
                .description(dto.getDescription())
                .createdBy(creator)
                .eventDate(dto.getEventDate())
                .endDate(dto.getEndDate())
                .location(dto.getLocation())
                .maxParticipants(dto.getMaxParticipants())
                .imageUrl(dto.getImageUrl())
                .active(true)
                .build();

        return mapper.toEventDTO(eventRepository.save(event));
    }

    @Override
    @Transactional(readOnly = true)
    public EventDTO getEventById(Long id) {
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Event not found with id: " + id));
        EventDTO dto = mapper.toEventDTO(event);
        dto.setCurrentRegistrations(registrationRepository.countByEventId(id).intValue());
        return dto;
    }

    @Override
    @Transactional(readOnly = true)
    public Page<EventDTO> getActiveEvents(Pageable pageable) {
        return eventRepository.findByActiveTrue(pageable).map(mapper::toEventDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<EventDTO> getEventsByCreator(Long userId, Pageable pageable) {
        return eventRepository.findByCreatedById(userId, pageable).map(mapper::toEventDTO);
    }

    @Override
    public EventDTO updateEvent(Long id, EventDTO dto) {
        log.info("Updating event: {}", id);
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Event not found with id: " + id));

        if (dto.getTitle() != null)
            event.setTitle(dto.getTitle());
        if (dto.getDescription() != null)
            event.setDescription(dto.getDescription());
        if (dto.getEventDate() != null)
            event.setEventDate(dto.getEventDate());
        if (dto.getEndDate() != null)
            event.setEndDate(dto.getEndDate());
        if (dto.getLocation() != null)
            event.setLocation(dto.getLocation());
        if (dto.getMaxParticipants() != null)
            event.setMaxParticipants(dto.getMaxParticipants());
        if (dto.getImageUrl() != null)
            event.setImageUrl(dto.getImageUrl());
        if (dto.getActive() != null)
            event.setActive(dto.getActive());

        return mapper.toEventDTO(eventRepository.save(event));
    }

    @Override
    public void deleteEvent(Long id) {
        if (!eventRepository.existsById(id)) {
            throw new EntityNotFoundException("Event not found with id: " + id);
        }
        eventRepository.deleteById(id);
    }

    @Override
    public EventRegistrationDTO registerForEvent(Long eventId, Long userId) {
        log.info("User {} registering for event {}", userId, eventId);

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new EntityNotFoundException("Event not found"));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        if (registrationRepository.existsByUserIdAndEventId(userId, eventId)) {
            throw new IllegalStateException("User already registered for this event");
        }

        if (event.getMaxParticipants() != null) {
            Long count = registrationRepository.countByEventId(eventId);
            if (count >= event.getMaxParticipants()) {
                throw new IllegalStateException("Event is full");
            }
        }

        EventRegistration reg = EventRegistration.builder()
                .event(event)
                .user(user)
                .registrationDate(LocalDateTime.now())
                .status(RegistrationStatus.REGISTERED)
                .build();

        return mapper.toEventRegistrationDTO(registrationRepository.save(reg));
    }

    @Override
    public EventRegistrationDTO cancelRegistration(Long registrationId) {
        EventRegistration reg = registrationRepository.findById(registrationId)
                .orElseThrow(() -> new EntityNotFoundException("Registration not found"));
        reg.setStatus(RegistrationStatus.CANCELLED);
        return mapper.toEventRegistrationDTO(registrationRepository.save(reg));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<EventRegistrationDTO> getRegistrationsByUser(Long userId, Pageable pageable) {
        return registrationRepository.findByUserId(userId, pageable).map(mapper::toEventRegistrationDTO);
    }
}
