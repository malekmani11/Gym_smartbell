package com.gymapp.controller;

import com.gymapp.dto.CheckInDTO;
import com.gymapp.service.CheckInService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/checkins")
@RequiredArgsConstructor
public class CheckInController {

    private final CheckInService checkInService;

    @PostMapping("/member/{memberId}/receptionist/{receptionistId}")
    public ResponseEntity<CheckInDTO> checkIn(
            @PathVariable Long memberId, @PathVariable Long receptionistId) {
        return ResponseEntity.status(HttpStatus.CREATED).body(checkInService.checkIn(memberId, receptionistId));
    }

    @PatchMapping("/member/{memberId}/checkout")
    public ResponseEntity<CheckInDTO> checkOut(@PathVariable Long memberId) {
        return ResponseEntity.ok(checkInService.checkOut(memberId));
    }

    @GetMapping("/member/{memberId}")
    public ResponseEntity<Page<CheckInDTO>> getCheckInsByMember(
            @PathVariable Long memberId, Pageable pageable) {
        return ResponseEntity.ok(checkInService.getCheckInsByMember(memberId, pageable));
    }

    @GetMapping("/member/{memberId}/active")
    public ResponseEntity<CheckInDTO> getActiveCheckIn(@PathVariable Long memberId) {
        return ResponseEntity.ok(checkInService.getActiveCheckIn(memberId));
    }
}
