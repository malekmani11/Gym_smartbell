package com.gymapp.controller;

import com.gymapp.dto.CoachDTO;
import com.gymapp.entity.enums.AvailabilityStatus;
import com.gymapp.service.CoachService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/coaches")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class CoachController {

    private final CoachService coachService;

    @PostMapping
    public ResponseEntity<CoachDTO> createCoachDirect(@RequestBody CoachDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(coachService.createCoachDirect(dto));
    }

    @PostMapping("/user/{userId}")
    public ResponseEntity<CoachDTO> createCoach(@PathVariable Long userId, @RequestBody CoachDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(coachService.createCoach(userId, dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<CoachDTO> getCoachById(@PathVariable Long id) {
        return ResponseEntity.ok(coachService.getCoachById(id));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<CoachDTO> getCoachByUserId(@PathVariable Long userId) {
        return ResponseEntity.ok(coachService.getCoachByUserId(userId));
    }

    @GetMapping
    public ResponseEntity<Page<CoachDTO>> getAllCoaches(
            @RequestParam(required = false) AvailabilityStatus status,
            Pageable pageable) {
        if (status != null) {
            return ResponseEntity.ok(coachService.getCoachesByStatus(status, pageable));
        }
        return ResponseEntity.ok(coachService.getAllCoaches(pageable));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CoachDTO> updateCoach(@PathVariable Long id, @RequestBody CoachDTO dto) {
        return ResponseEntity.ok(coachService.updateCoach(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCoach(@PathVariable Long id) {
        coachService.deleteCoach(id);
        return ResponseEntity.noContent().build();
    }
}
