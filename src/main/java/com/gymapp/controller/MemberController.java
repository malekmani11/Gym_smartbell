package com.gymapp.controller;

import com.gymapp.dto.MemberDTO;
import com.gymapp.entity.enums.MembershipStatus;
import com.gymapp.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/members")
@RequiredArgsConstructor
public class MemberController {

    private final MemberService memberService;

    @PostMapping("/user/{userId}")
    public ResponseEntity<MemberDTO> createMember(@PathVariable Long userId, @RequestBody MemberDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(memberService.createMember(userId, dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<MemberDTO> getMemberById(@PathVariable Long id) {
        return ResponseEntity.ok(memberService.getMemberById(id));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<MemberDTO> getMemberByUserId(@PathVariable Long userId) {
        return ResponseEntity.ok(memberService.getMemberByUserId(userId));
    }

    @GetMapping
    public ResponseEntity<Page<MemberDTO>> getAllMembers(
            @RequestParam(required = false) MembershipStatus status,
            Pageable pageable) {
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

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteMember(@PathVariable Long id) {
        memberService.deleteMember(id);
        return ResponseEntity.noContent().build();
    }
}
