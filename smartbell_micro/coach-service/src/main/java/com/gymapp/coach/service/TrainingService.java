package com.gymapp.coach.service;

import com.gymapp.coach.dto.ExerciseDTO;
import com.gymapp.coach.dto.TrainingProgramDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface TrainingService {

    // Training Programs
    TrainingProgramDTO createProgram(TrainingProgramDTO dto);
    TrainingProgramDTO getProgramById(Long id);
    Page<TrainingProgramDTO> getProgramsByMember(Long memberId, Pageable pageable);
    Page<TrainingProgramDTO> getProgramsByCoach(Long coachId, Pageable pageable);
    TrainingProgramDTO updateProgram(Long id, TrainingProgramDTO dto);
    void deleteProgram(Long id);

    // Exercises (machineId référence machine-service, pas de JPA cross-service)
    ExerciseDTO createExercise(ExerciseDTO dto);
    ExerciseDTO getExerciseById(Long id);
    Page<ExerciseDTO> getAllExercises(Pageable pageable);
    Page<ExerciseDTO> getExercisesByMuscleGroup(String muscleGroup, Pageable pageable);
    ExerciseDTO updateExercise(Long id, ExerciseDTO dto);
    void deleteExercise(Long id);
}
