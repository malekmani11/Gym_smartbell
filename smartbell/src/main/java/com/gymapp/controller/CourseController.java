package com.gymapp.controller;

import com.gymapp.dto.CourseDTO;
import com.gymapp.dto.CourseReservationDTO;
import com.gymapp.service.CourseService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/courses")
@RequiredArgsConstructor
public class CourseController {

    private final CourseService courseService;

    @PostMapping
    public ResponseEntity<CourseDTO> createCourse(@RequestBody CourseDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(courseService.createCourse(dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<CourseDTO> getCourseById(@PathVariable Long id) {
        return ResponseEntity.ok(courseService.getCourseById(id));
    }

    @GetMapping
    public ResponseEntity<Page<CourseDTO>> getActiveCourses(Pageable pageable) {
        return ResponseEntity.ok(courseService.getActiveCourses(pageable));
    }

    @GetMapping("/coach/{coachId}")
    public ResponseEntity<Page<CourseDTO>> getCoursesByCoach(
            @PathVariable Long coachId, Pageable pageable) {
        return ResponseEntity.ok(courseService.getCoursesByCoach(coachId, pageable));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CourseDTO> updateCourse(@PathVariable Long id, @RequestBody CourseDTO dto) {
        return ResponseEntity.ok(courseService.updateCourse(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCourse(@PathVariable Long id) {
        courseService.deleteCourse(id);
        return ResponseEntity.noContent().build();
    }

    // ── Reservations ─────────────────────────────────────────────────────────

    @PostMapping("/reservations")
    public ResponseEntity<CourseReservationDTO> createReservation(@RequestBody CourseReservationDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(courseService.createReservation(dto));
    }

    @GetMapping("/reservations/member/{memberId}")
    public ResponseEntity<Page<CourseReservationDTO>> getReservationsByMember(
            @PathVariable Long memberId, Pageable pageable) {
        return ResponseEntity.ok(courseService.getReservationsByMember(memberId, pageable));
    }

    @PatchMapping("/reservations/{id}/cancel")
    public ResponseEntity<CourseReservationDTO> cancelReservation(@PathVariable Long id) {
        return ResponseEntity.ok(courseService.cancelReservation(id));
    }
}
