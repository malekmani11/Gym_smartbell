package com.gymapp.controller;

import com.gymapp.dto.EventDTO;
import com.gymapp.dto.EventRegistrationDTO;
import com.gymapp.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    @PostMapping("/creator/{creatorId}")
    public ResponseEntity<EventDTO> createEvent(
            @PathVariable Long creatorId, @RequestBody EventDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(eventService.createEvent(dto, creatorId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<EventDTO> getEventById(@PathVariable Long id) {
        return ResponseEntity.ok(eventService.getEventById(id));
    }

    @GetMapping
    public ResponseEntity<Page<EventDTO>> getActiveEvents(Pageable pageable) {
        return ResponseEntity.ok(eventService.getActiveEvents(pageable));
    }

    @GetMapping("/creator/{userId}")
    public ResponseEntity<Page<EventDTO>> getEventsByCreator(
            @PathVariable Long userId, Pageable pageable) {
        return ResponseEntity.ok(eventService.getEventsByCreator(userId, pageable));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EventDTO> updateEvent(@PathVariable Long id, @RequestBody EventDTO dto) {
        return ResponseEntity.ok(eventService.updateEvent(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEvent(@PathVariable Long id) {
        eventService.deleteEvent(id);
        return ResponseEntity.noContent().build();
    }

    // ── Registrations ────────────────────────────────────────────────────────

    @PostMapping("/{eventId}/register/user/{userId}")
    public ResponseEntity<EventRegistrationDTO> registerForEvent(
            @PathVariable Long eventId, @PathVariable Long userId) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(eventService.registerForEvent(eventId, userId));
    }

    @PatchMapping("/registrations/{id}/cancel")
    public ResponseEntity<EventRegistrationDTO> cancelRegistration(@PathVariable Long id) {
        return ResponseEntity.ok(eventService.cancelRegistration(id));
    }

    @GetMapping("/registrations/user/{userId}")
    public ResponseEntity<Page<EventRegistrationDTO>> getRegistrationsByUser(
            @PathVariable Long userId, Pageable pageable) {
        return ResponseEntity.ok(eventService.getRegistrationsByUser(userId, pageable));
    }
}
