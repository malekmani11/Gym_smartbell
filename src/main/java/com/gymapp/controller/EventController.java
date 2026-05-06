package com.gymapp.controller;

import com.gymapp.dto.EventDTO;
import com.gymapp.dto.EventRegistrationDTO;
import com.gymapp.security.JwtService;
import com.gymapp.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;
    private final JwtService jwtService;

    private String extractEmail(String authHeader) {
        String token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        return jwtService.extractUsername(token);
    }

    @PostMapping("/creator/{creatorId}")
    public ResponseEntity<EventDTO> createEvent(
            @PathVariable Long creatorId, @Valid @RequestBody EventDTO dto) {
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
    public ResponseEntity<EventDTO> updateEvent(@PathVariable Long id, @Valid @RequestBody EventDTO dto) {
        return ResponseEntity.ok(eventService.updateEvent(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEvent(@PathVariable Long id) {
        eventService.deleteEvent(id);
        return ResponseEntity.noContent().build();
    }

    // ── Registrations (admin/userId) ─────────────────────────────────────────

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

    // ── Registrations (JWT-based, mobile) ────────────────────────────────────

    @GetMapping("/{eventId}/registrations")
    public ResponseEntity<List<EventRegistrationDTO>> getEventRegistrations(
            @PathVariable Long eventId) {
        return ResponseEntity.ok(eventService.getEventRegistrations(eventId));
    }

    @PostMapping("/{eventId}/register")
    public ResponseEntity<EventRegistrationDTO> registerSelf(
            @PathVariable Long eventId,
            @RequestHeader("Authorization") String authHeader) {
        String email = extractEmail(authHeader);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(eventService.registerByEmail(eventId, email));
    }

    @DeleteMapping("/{eventId}/register")
    public ResponseEntity<Void> unregisterSelf(
            @PathVariable Long eventId,
            @RequestHeader("Authorization") String authHeader) {
        String email = extractEmail(authHeader);
        eventService.unregisterByEmail(eventId, email);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/my-registrations")
    public ResponseEntity<List<EventRegistrationDTO>> getMyRegistrations(
            @RequestHeader("Authorization") String authHeader) {
        String email = extractEmail(authHeader);
        return ResponseEntity.ok(eventService.getMyRegistrationsByEmail(email));
    }
}
