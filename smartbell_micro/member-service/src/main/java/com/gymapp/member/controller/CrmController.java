package com.gymapp.member.controller;

import com.gymapp.member.dto.CrmMemberDTO;
import com.gymapp.member.service.CrmService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/crm")
@RequiredArgsConstructor
public class CrmController {

    private final CrmService crmService;

    @GetMapping("/pipeline")
    public ResponseEntity<Map<String, List<CrmMemberDTO>>> getPipeline() {
        return ResponseEntity.ok(crmService.getPipeline());
    }

    @PutMapping("/member/{id}/status")
    public ResponseEntity<CrmMemberDTO> updateStage(
            @PathVariable Long id,
            @RequestParam String stage) {
        return ResponseEntity.ok(crmService.updateStage(id, stage));
    }

    @PostMapping("/member/{id}/note")
    public ResponseEntity<CrmMemberDTO> addNote(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(crmService.addNote(id, body.get("note")));
    }
}
