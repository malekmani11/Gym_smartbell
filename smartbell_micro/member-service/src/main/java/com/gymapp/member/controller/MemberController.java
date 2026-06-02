package com.gymapp.member.controller;

import com.gymapp.member.dto.MeasurementDTO;
import com.gymapp.member.dto.MemberDTO;
import com.gymapp.member.entity.enums.MembershipStatus;
import com.gymapp.member.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/members")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class MemberController {

    private final MemberService memberService;

    @PostMapping
    public ResponseEntity<MemberDTO> createMemberDirect(@RequestBody MemberDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(memberService.createMemberDirect(dto));
    }

    @PostMapping("/user/{userId}")
    public ResponseEntity<MemberDTO> createMember(@PathVariable Long userId, @RequestBody MemberDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(memberService.createMember(userId, dto));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER', 'COACH')")
    public ResponseEntity<MemberDTO> getMemberById(@PathVariable Long id) {
        return ResponseEntity.ok(memberService.getMemberById(id));
    }

    @GetMapping("/user/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER', 'COACH')")
    public ResponseEntity<MemberDTO> getMemberByUserId(@PathVariable Long userId) {
        return ResponseEntity.ok(memberService.getMemberByUserId(userId));
    }

    @GetMapping
    public ResponseEntity<Page<MemberDTO>> getAllMembers(
            @RequestParam(required = false) MembershipStatus status,
            @RequestParam(required = false) String search,
            Pageable pageable) {
        if (search != null && !search.isBlank()) {
            return ResponseEntity.ok(memberService.searchMembers(search.trim(), pageable));
        }
        if (status != null) {
            return ResponseEntity.ok(memberService.getMembersByStatus(status, pageable));
        }
        return ResponseEntity.ok(memberService.getAllMembers(pageable));
    }

    @PutMapping("/{id}")
    public ResponseEntity<MemberDTO> updateMember(@PathVariable Long id, @RequestBody MemberDTO dto) {
        return ResponseEntity.ok(memberService.updateMember(id, dto));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<Void> updateMembershipStatus(@PathVariable Long id, @RequestParam MembershipStatus status) {
        memberService.updateMembershipStatus(id, status);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{id}/messaging-access")
    public ResponseEntity<Void> setMessagingAccess(
            @PathVariable Long id,
            @RequestParam boolean enabled) {
        memberService.setMessagingEnabled(id, enabled);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{id}/assign-coach")
    public ResponseEntity<Void> assignCoach(
            @PathVariable Long id,
            @RequestParam Long coachId) {
        memberService.assignCoach(id, coachId);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{id}/unassign-coach")
    public ResponseEntity<Void> unassignCoach(@PathVariable Long id) {
        memberService.assignCoach(id, null);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteMember(@PathVariable Long id) {
        memberService.deleteMember(id);
        return ResponseEntity.noContent().build();
    }

    // ── Measurements (progress tracking) ──────────────────────────────────────

    @GetMapping("/{memberId}/measurements")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER', 'COACH')")
    public ResponseEntity<List<MeasurementDTO>> getMeasurements(@PathVariable Long memberId) {
        return ResponseEntity.ok(memberService.getMeasurements(memberId));
    }

    @PostMapping("/{memberId}/measurements")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER')")
    public ResponseEntity<MeasurementDTO> addMeasurement(
            @PathVariable Long memberId,
            @RequestBody MeasurementDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(memberService.addMeasurement(memberId, dto));
    }

    @DeleteMapping("/{memberId}/measurements/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER')")
    public ResponseEntity<Void> deleteMeasurement(
            @PathVariable Long memberId,
            @PathVariable Long id) {
        memberService.deleteMeasurement(memberId, id);
        return ResponseEntity.noContent().build();
    }
}
