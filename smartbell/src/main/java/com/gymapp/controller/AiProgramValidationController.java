package com.gymapp.controller;

import com.gymapp.dto.SavedAiProgramDto;
import com.gymapp.dto.ValidateProgramRequest;
import com.gymapp.entity.enums.AiProgramStatus;
import com.gymapp.service.AiProgramValidationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/ai/programs")
@RequiredArgsConstructor
public class AiProgramValidationController {

    private final AiProgramValidationService validationService;

    @GetMapping("/coach/{coachId}")
    @PreAuthorize("hasAnyRole('ADMIN','COACH')")
    public ResponseEntity<List<SavedAiProgramDto>> getProgramsByCoach(
            @PathVariable Long coachId,
            @RequestParam(required = false) AiProgramStatus status) {
        return ResponseEntity.ok(validationService.getProgramsByCoach(coachId, status));
    }

    @GetMapping("/member/{memberId}")
    @PreAuthorize("hasAnyRole('ADMIN','COACH','MEMBER')")
    public ResponseEntity<List<SavedAiProgramDto>> getProgramsByMember(@PathVariable Long memberId) {
        return ResponseEntity.ok(validationService.getProgramsByMember(memberId));
    }

    @PutMapping("/{programId}/validate")
    @PreAuthorize("hasAnyRole('ADMIN','COACH')")
    public ResponseEntity<SavedAiProgramDto> validateProgram(
            @PathVariable Long programId,
            @RequestParam Long coachId,
            @Valid @RequestBody ValidateProgramRequest request) {
        return ResponseEntity.ok(validationService.validateProgram(programId, coachId, request));
    }
}
