package com.gymapp.event.controller;

import com.gymapp.event.dto.EventDTO;
import com.gymapp.event.dto.EventRegistrationDTO;
import com.gymapp.event.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    /**
     * Extrait l'email depuis le payload JWT (Base64Url) sans bibliothèque externe.
     * Le claim "sub" contient l'email tel que défini par member-service JwtService.
     */
    private String extractEmail(String authHeader) {
        String token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        String[] parts = token.split("\\.");
        if (parts.length < 2) throw new IllegalArgumentException("Token JWT invalide");
        String padded = parts[1] + "=".repeat((4 - parts[1].length() % 4) % 4);
        String json = new String(java.util.Base64.getUrlDecoder().decode(padded));
        int idx = json.indexOf("\"sub\":\"");
        if (idx < 0) throw new IllegalArgumentException("Claim 'sub' introuvable dans le token");
        int start = idx + 7;
        return json.substring(start, json.indexOf("\"", start));
    }

    @PostMapping
    public ResponseEntity<EventDTO> createEvent(
            @Valid @RequestBody EventDTO dto,
            @RequestHeader(value = "X-User-Id", required = false) Long creatorId) {
        if (creatorId == null) creatorId = dto.getCreatedById();
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

    // ── Inscriptions admin ────────────────────────────────────────────────────

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

    // ── Inscriptions JWT-based (mobile / Angular) ─────────────────────────────

    @GetMapping("/{eventId}/registrations")
    public ResponseEntity<List<EventRegistrationDTO>> getEventRegistrations(@PathVariable Long eventId) {
        return ResponseEntity.ok(eventService.getEventRegistrations(eventId));
    }

    @PostMapping("/{eventId}/register")
    public ResponseEntity<EventRegistrationDTO> registerSelf(
            @PathVariable Long eventId,
            @RequestHeader("Authorization") String authHeader) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(eventService.registerByEmail(eventId, extractEmail(authHeader)));
    }

    @DeleteMapping("/{eventId}/register")
    public ResponseEntity<Void> unregisterSelf(
            @PathVariable Long eventId,
            @RequestHeader("Authorization") String authHeader) {
        eventService.unregisterByEmail(eventId, extractEmail(authHeader));
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/my-registrations")
    public ResponseEntity<List<EventRegistrationDTO>> getMyRegistrations(
            @RequestHeader("Authorization") String authHeader) {
        return ResponseEntity.ok(eventService.getMyRegistrationsByEmail(extractEmail(authHeader)));
    }
}
