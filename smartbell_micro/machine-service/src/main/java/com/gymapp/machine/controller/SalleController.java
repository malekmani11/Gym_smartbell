package com.gymapp.machine.controller;

import com.gymapp.machine.dto.SalleDTO;
import com.gymapp.machine.dto.SalleOccupancyDTO;
import com.gymapp.machine.entity.enums.SalleStatus;
import com.gymapp.machine.service.SalleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/salles")
@RequiredArgsConstructor
public class SalleController {

    private final SalleService salleService;

    @GetMapping
    public ResponseEntity<List<SalleDTO>> getAll(
            @RequestParam(required = false) SalleStatus status) {
        if (status != null) {
            return ResponseEntity.ok(salleService.getByStatus(status));
        }
        return ResponseEntity.ok(salleService.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<SalleDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(salleService.getById(id));
    }

    @PostMapping
    public ResponseEntity<SalleDTO> create(@Valid @RequestBody SalleDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(salleService.create(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<SalleDTO> update(
            @PathVariable Long id, @Valid @RequestBody SalleDTO dto) {
        return ResponseEntity.ok(salleService.update(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        salleService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/occupancy")
    public ResponseEntity<List<SalleOccupancyDTO>> getAllOccupancy() {
        return ResponseEntity.ok(salleService.getAllOccupancies());
    }

    @GetMapping("/{id}/occupancy")
    public ResponseEntity<SalleOccupancyDTO> getOccupancy(@PathVariable Long id) {
        return ResponseEntity.ok(salleService.getOccupancy(id));
    }
}
