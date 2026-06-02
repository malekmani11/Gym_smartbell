package com.gymapp.member.controller;

import com.gymapp.member.dto.SubscriptionPlanDTO;
import com.gymapp.member.service.SubscriptionPlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/subscription-plans")
@RequiredArgsConstructor
public class SubscriptionPlanController {

    private final SubscriptionPlanService planService;

    @PostMapping
    public ResponseEntity<SubscriptionPlanDTO> createPlan(@RequestBody SubscriptionPlanDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(planService.createPlan(dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<SubscriptionPlanDTO> getPlanById(@PathVariable Long id) {
        return ResponseEntity.ok(planService.getPlanById(id));
    }

    @GetMapping
    public ResponseEntity<List<SubscriptionPlanDTO>> getAllPlans(
            @RequestParam(defaultValue = "true") boolean activeOnly) {
        if (activeOnly) {
            return ResponseEntity.ok(planService.getAllActivePlans());
        }
        return ResponseEntity.ok(planService.getAllPlans());
    }

    @PutMapping("/{id}")
    public ResponseEntity<SubscriptionPlanDTO> updatePlan(@PathVariable Long id, @RequestBody SubscriptionPlanDTO dto) {
        return ResponseEntity.ok(planService.updatePlan(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePlan(@PathVariable Long id) {
        planService.deletePlan(id);
        return ResponseEntity.noContent().build();
    }
}
