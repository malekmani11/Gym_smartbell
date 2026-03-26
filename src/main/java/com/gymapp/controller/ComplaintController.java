package com.gymapp.controller;

import com.gymapp.dto.ComplaintDTO;
import com.gymapp.entity.enums.ComplaintStatus;
import com.gymapp.service.ComplaintService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/complaints")
@RequiredArgsConstructor
public class ComplaintController {

    private final ComplaintService complaintService;

    @PostMapping("/user/{userId}")
    public ResponseEntity<ComplaintDTO> createComplaint(
            @PathVariable Long userId, @RequestBody ComplaintDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(complaintService.createComplaint(userId, dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ComplaintDTO> getComplaintById(@PathVariable Long id) {
        return ResponseEntity.ok(complaintService.getComplaintById(id));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<Page<ComplaintDTO>> getComplaintsByUser(
            @PathVariable Long userId, Pageable pageable) {
        return ResponseEntity.ok(complaintService.getComplaintsByUser(userId, pageable));
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<Page<ComplaintDTO>> getComplaintsByStatus(
            @PathVariable ComplaintStatus status, Pageable pageable) {
        return ResponseEntity.ok(complaintService.getComplaintsByStatus(status, pageable));
    }

    @GetMapping
    public ResponseEntity<Page<ComplaintDTO>> getAllComplaints(Pageable pageable) {
        return ResponseEntity.ok(complaintService.getAllComplaints(pageable));
    }

    @PatchMapping("/{id}/respond")
    public ResponseEntity<ComplaintDTO> respondToComplaint(
            @PathVariable Long id,
            @RequestParam String response,
            @RequestParam ComplaintStatus status) {
        return ResponseEntity.ok(complaintService.respondToComplaint(id, response, status));
    }
}
