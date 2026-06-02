package com.gymapp.controller;

import com.gymapp.dto.MemberDTO;
import com.gymapp.entity.enums.MembershipStatus;
import com.gymapp.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

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
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER')")
    public ResponseEntity<MemberDTO> getMemberById(@PathVariable Long id) {
        return ResponseEntity.ok(memberService.getMemberById(id));
    }

    @GetMapping("/user/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER')")
    public ResponseEntity<MemberDTO> getMemberByUserId(@PathVariable Long userId) {
        return ResponseEntity.ok(memberService.getMemberByUserId(userId));
    }

    @GetMapping
    public ResponseEntity<Page<MemberDTO>> getAllMembers(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search,
            Pageable pageable) {
        if (search != null && !search.isBlank()) {
            return ResponseEntity.ok(memberService.searchMembers(search.trim(), pageable));
        }
        if (status != null && !status.isBlank()) {
            try {
                MembershipStatus membershipStatus = MembershipStatus.valueOf(status.toUpperCase());
                return ResponseEntity.ok(memberService.getMembersByStatus(membershipStatus, pageable));
            } catch (IllegalArgumentException e) {
                // Si le statut est invalide, on ignore le filtre ou on pourrait retourner une erreur.
                // Ici on choisit d'ignorer le filtre invalide pour éviter l'erreur 400 automatique.
            }
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

    @PatchMapping("/{id}/assign-coach")
    public ResponseEntity<Void> assignCoach(
            @PathVariable Long id,
            @RequestParam(required = false) Long coachId) {
        memberService.assignCoach(id, coachId);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{id}/messaging-access")
    public ResponseEntity<Void> setMessagingAccess(
            @PathVariable Long id,
            @RequestParam boolean enabled) {
        memberService.setMessagingEnabled(id, enabled);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteMember(@PathVariable Long id) {
        memberService.deleteMember(id);
        return ResponseEntity.noContent().build();
    }
}
