package com.gymapp.coach.controller;

import com.gymapp.coach.dto.AiProgramRequest;
import com.gymapp.coach.dto.AiProgramResponse;
import com.gymapp.coach.service.AiProgramService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
@Slf4j
public class AiProgramController {

    private final AiProgramService aiProgramService;

    @PostMapping("/generate-program/{memberId}")
    public ResponseEntity<AiProgramResponse> generateProgram(
            @PathVariable Long memberId,
            @RequestBody @Valid AiProgramRequest request) {
        log.info("POST /api/ai/generate-program/{}", memberId);
        return ResponseEntity.ok(aiProgramService.generateProgram(memberId, request));
    }
}
