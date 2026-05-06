package com.gymapp.controller;

import com.gymapp.dto.MachineDTO;
import com.gymapp.entity.enums.MachineStatus;
import com.gymapp.service.MachineService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/machines")
@RequiredArgsConstructor
public class MachineController {

    private final MachineService machineService;

    @GetMapping
    public ResponseEntity<List<MachineDTO>> getAll(
            @RequestParam(required = false) MachineStatus status) {
        if (status != null) {
            return ResponseEntity.ok(machineService.getByStatus(status));
        }
        return ResponseEntity.ok(machineService.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<MachineDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(machineService.getById(id));
    }

    @PostMapping
    public ResponseEntity<MachineDTO> create(@Valid @RequestBody MachineDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(machineService.create(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<MachineDTO> update(
            @PathVariable Long id, @Valid @RequestBody MachineDTO dto) {
        return ResponseEntity.ok(machineService.update(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        machineService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/qrcode")
    public ResponseEntity<Map<String, String>> getQrCode(@PathVariable Long id) {
        return ResponseEntity.ok(Map.of("qrData", machineService.getQrCodeData(id)));
    }
}
