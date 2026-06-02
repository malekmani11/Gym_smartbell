package com.gymapp.coach.controller;

import com.gymapp.coach.dto.ExerciseDTO;
import com.gymapp.coach.dto.TrainingProgramDTO;
import com.gymapp.coach.service.TrainingService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/training")
@RequiredArgsConstructor
public class TrainingController {

    private final TrainingService trainingService;

    // ── Training Programs ────────────────────────────────────────────────────

    @PostMapping("/programs")
    public ResponseEntity<TrainingProgramDTO> createProgram(@RequestBody TrainingProgramDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(trainingService.createProgram(dto));
    }

    @GetMapping("/programs/{id}")
    public ResponseEntity<TrainingProgramDTO> getProgramById(@PathVariable Long id) {
        return ResponseEntity.ok(trainingService.getProgramById(id));
    }

    @GetMapping("/programs/member/{memberId}")
    public ResponseEntity<Page<TrainingProgramDTO>> getProgramsByMember(
            @PathVariable Long memberId, Pageable pageable) {
        return ResponseEntity.ok(trainingService.getProgramsByMember(memberId, pageable));
    }

    @GetMapping("/programs/coach/{coachId}")
    public ResponseEntity<Page<TrainingProgramDTO>> getProgramsByCoach(
            @PathVariable Long coachId, Pageable pageable) {
        return ResponseEntity.ok(trainingService.getProgramsByCoach(coachId, pageable));
    }

    @PutMapping("/programs/{id}")
    public ResponseEntity<TrainingProgramDTO> updateProgram(
            @PathVariable Long id, @RequestBody TrainingProgramDTO dto) {
        return ResponseEntity.ok(trainingService.updateProgram(id, dto));
    }

    @DeleteMapping("/programs/{id}")
    public ResponseEntity<Void> deleteProgram(@PathVariable Long id) {
        trainingService.deleteProgram(id);
        return ResponseEntity.noContent().build();
    }

    // ── Exercises ─────────────────────────────────────────────────────────────

    @PostMapping("/exercises")
    public ResponseEntity<ExerciseDTO> createExercise(@RequestBody ExerciseDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(trainingService.createExercise(dto));
    }

    @GetMapping("/exercises/{id}")
    public ResponseEntity<ExerciseDTO> getExerciseById(@PathVariable Long id) {
        return ResponseEntity.ok(trainingService.getExerciseById(id));
    }

    @GetMapping("/exercises")
    public ResponseEntity<Page<ExerciseDTO>> getAllExercises(
            @RequestParam(required = false) String muscleGroup, Pageable pageable) {
        if (muscleGroup != null) {
            return ResponseEntity.ok(trainingService.getExercisesByMuscleGroup(muscleGroup, pageable));
        }
        return ResponseEntity.ok(trainingService.getAllExercises(pageable));
    }

    @PutMapping("/exercises/{id}")
    public ResponseEntity<ExerciseDTO> updateExercise(
            @PathVariable Long id, @RequestBody ExerciseDTO dto) {
        return ResponseEntity.ok(trainingService.updateExercise(id, dto));
    }

    @DeleteMapping("/exercises/{id}")
    public ResponseEntity<Void> deleteExercise(@PathVariable Long id) {
        trainingService.deleteExercise(id);
        return ResponseEntity.noContent().build();
    }
}
