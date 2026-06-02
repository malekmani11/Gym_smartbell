package com.gymapp.controller;

import com.gymapp.dto.AbsenceRequestDTO;
import com.gymapp.entity.enums.AbsenceStatus;
import com.gymapp.service.AbsenceRequestService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/absence-requests")
@RequiredArgsConstructor
public class AbsenceRequestController {

    private final AbsenceRequestService absenceRequestService;

    // ── Coach ────────────────────────────────────────────────────────────────

    @PostMapping("/coach/{coachId}")
    public ResponseEntity<AbsenceRequestDTO> createRequest(
            @PathVariable Long coachId,
            @RequestBody AbsenceRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(absenceRequestService.createRequest(coachId, dto));
    }

    @GetMapping("/coach/{coachId}")
    public ResponseEntity<Page<AbsenceRequestDTO>> getByCoach(
            @PathVariable Long coachId, Pageable pageable) {
        return ResponseEntity.ok(absenceRequestService.getRequestsByCoach(coachId, pageable));
    }

    // ── Admin ────────────────────────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<Page<AbsenceRequestDTO>> getAll(
            @RequestParam(required = false) AbsenceStatus status,
            Pageable pageable) {
        if (status != null) {
            return ResponseEntity.ok(absenceRequestService.getRequestsByStatus(status, pageable));
        }
        return ResponseEntity.ok(absenceRequestService.getAllRequests(pageable));
    }

    @PatchMapping("/{id}/approve")
    public ResponseEntity<AbsenceRequestDTO> approve(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        String note = body != null ? body.get("adminNote") : null;
        return ResponseEntity.ok(absenceRequestService.approve(id, note));
    }

    @PatchMapping("/{id}/reject")
    public ResponseEntity<AbsenceRequestDTO> reject(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        String note = body != null ? body.get("adminNote") : null;
        return ResponseEntity.ok(absenceRequestService.reject(id, note));
    }
}
