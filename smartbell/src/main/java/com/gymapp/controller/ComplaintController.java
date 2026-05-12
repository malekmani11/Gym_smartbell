package com.gymapp.controller;

import com.gymapp.dto.ComplaintDTO;
import com.gymapp.dto.RespondComplaintRequest;
import com.gymapp.entity.enums.ComplaintStatus;
import com.gymapp.service.ComplaintService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/complaints")
@RequiredArgsConstructor
public class ComplaintController {

    private final ComplaintService complaintService;

    // Membres et coaches peuvent déposer une plainte
    @PostMapping("/user/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN','MEMBER','COACH')")
    public ResponseEntity<ComplaintDTO> createComplaint(
            @PathVariable Long userId, @RequestBody ComplaintDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(complaintService.createComplaint(userId, dto));
    }

    // Admin seulement pour voir/répondre
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ComplaintDTO> getComplaintById(@PathVariable Long id) {
        return ResponseEntity.ok(complaintService.getComplaintById(id));
    }

    // Membre peut voir ses propres plaintes
    @GetMapping("/user/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN','MEMBER','COACH')")
    public ResponseEntity<Page<ComplaintDTO>> getComplaintsByUser(
            @PathVariable Long userId, Pageable pageable) {
        return ResponseEntity.ok(complaintService.getComplaintsByUser(userId, pageable));
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<ComplaintDTO>> getComplaintsByStatus(
            @PathVariable ComplaintStatus status, Pageable pageable) {
        return ResponseEntity.ok(complaintService.getComplaintsByStatus(status, pageable));
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<ComplaintDTO>> getAllComplaints(Pageable pageable) {
        return ResponseEntity.ok(complaintService.getAllComplaints(pageable));
    }

    @PatchMapping("/{id}/respond")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ComplaintDTO> respondToComplaint(
            @PathVariable Long id,
            @RequestBody RespondComplaintRequest req) {
        return ResponseEntity.ok(complaintService.respondToComplaint(id, req.getResponse(), req.getStatus()));
    }

    @PatchMapping("/{id}/read")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ComplaintDTO> markAsRead(@PathVariable Long id) {
        return ResponseEntity.ok(complaintService.markAsRead(id));
    }
}
