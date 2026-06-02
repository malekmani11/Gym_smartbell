package com.gymapp.controller;

import com.gymapp.dto.CheckInDTO;
import com.gymapp.service.CheckInService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/checkins")
@RequiredArgsConstructor
public class CheckInController {

    private final CheckInService checkInService;

    @PostMapping("/member/{memberId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER')")
    public ResponseEntity<CheckInDTO> checkIn(@PathVariable Long memberId) {
        return ResponseEntity.ok(checkInService.checkIn(memberId));
    }

    @PutMapping("/checkout/{memberId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER')")
    public ResponseEntity<CheckInDTO> checkOut(@PathVariable Long memberId) {
        return ResponseEntity.ok(checkInService.checkOut(memberId));
    }

    @GetMapping("/today")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<CheckInDTO>> getTodayCheckIns() {
        return ResponseEntity.ok(checkInService.getTodayCheckIns());
    }

    @GetMapping("/member/{memberId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MEMBER')")
    public ResponseEntity<List<CheckInDTO>> getMemberCheckIns(@PathVariable Long memberId) {
        return ResponseEntity.ok(checkInService.getCheckInsByMember(memberId));
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<CheckInDTO>> getAll(Pageable pageable) {
        return ResponseEntity.ok(checkInService.getAll(pageable));
    }
}
