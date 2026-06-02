package com.gymapp.controller;

import com.gymapp.dto.AttendanceDto;
import com.gymapp.dto.RecordAttendanceRequest;
import com.gymapp.service.AttendanceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/attendances")
@RequiredArgsConstructor
public class AttendanceController {

    private final AttendanceService attendanceService;

    @PostMapping("/course/{courseId}")
    @PreAuthorize("hasAnyRole('ADMIN','COACH')")
    public ResponseEntity<List<AttendanceDto>> recordAttendance(
            @PathVariable Long courseId,
            @Valid @RequestBody RecordAttendanceRequest request) {
        return ResponseEntity.ok(attendanceService.recordAttendance(courseId, request));
    }

    @GetMapping("/course/{courseId}")
    @PreAuthorize("hasAnyRole('ADMIN','COACH')")
    public ResponseEntity<List<AttendanceDto>> getAttendanceByCourseAndDate(
            @PathVariable Long courseId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(attendanceService.getAttendanceByCourseAndDate(courseId, date));
    }

    @GetMapping("/member/{memberId}")
    @PreAuthorize("hasAnyRole('ADMIN','COACH','MEMBER')")
    public ResponseEntity<List<AttendanceDto>> getAttendanceByMember(@PathVariable Long memberId) {
        return ResponseEntity.ok(attendanceService.getAttendanceByMember(memberId));
    }
}
