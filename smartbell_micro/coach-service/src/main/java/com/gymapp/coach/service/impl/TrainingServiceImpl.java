package com.gymapp.coach.service.impl;

import com.gymapp.coach.dto.ExerciseDTO;
import com.gymapp.coach.dto.TrainingProgramDTO;
import com.gymapp.coach.dto.TrainingProgramExerciseDTO;
import com.gymapp.coach.entity.Coach;
import com.gymapp.coach.entity.Exercise;
import com.gymapp.coach.entity.TrainingProgram;
import com.gymapp.coach.entity.TrainingProgramExercise;
import com.gymapp.coach.mapper.EntityMapper;
import com.gymapp.coach.repository.CoachRepository;
import com.gymapp.coach.repository.ExerciseRepository;
import com.gymapp.coach.repository.TrainingProgramExerciseRepository;
import com.gymapp.coach.repository.TrainingProgramRepository;
import com.gymapp.coach.service.TrainingService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class TrainingServiceImpl implements TrainingService {

    private final TrainingProgramRepository programRepository;
    private final TrainingProgramExerciseRepository programExerciseRepository;
    private final ExerciseRepository exerciseRepository;
    private final CoachRepository coachRepository;
    private final EntityMapper mapper;

    // ── Training Programs ──────────────────────────────────────────────────────

    @Override
    public TrainingProgramDTO createProgram(TrainingProgramDTO dto) {
        log.info("Creating training program: {}", dto.getName());
        Coach coach = coachRepository.findById(dto.getCoachId())
                .orElseThrow(() -> new EntityNotFoundException("Coach not found"));

        TrainingProgram program = TrainingProgram.builder()
                .name(dto.getName())
                .description(dto.getDescription())
                .coach(coach)
                .memberId(dto.getMemberId())
                .startDate(dto.getStartDate())
                .endDate(dto.getEndDate())
                .build();

        TrainingProgram saved = programRepository.save(program);

        if (dto.getExercises() != null) {
            for (TrainingProgramExerciseDTO exDto : dto.getExercises()) {
                Exercise exercise = exerciseRepository.findById(exDto.getExerciseId())
                        .orElseThrow(() -> new EntityNotFoundException("Exercise not found: " + exDto.getExerciseId()));

                TrainingProgramExercise tpe = TrainingProgramExercise.builder()
                        .trainingProgram(saved)
                        .exercise(exercise)
                        .sets(exDto.getSets())
                        .reps(exDto.getReps())
                        .restSeconds(exDto.getRestSeconds())
                        .dayNumber(exDto.getDayNumber())
                        .orderIndex(exDto.getOrderIndex())
                        .build();
                programExerciseRepository.save(tpe);
            }
        }

        return mapper.toTrainingProgramDTO(programRepository.findById(saved.getId()).get());
    }

    @Override
    @Transactional(readOnly = true)
    public TrainingProgramDTO getProgramById(Long id) {
        return mapper.toTrainingProgramDTO(programRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Program not found with id: " + id)));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<TrainingProgramDTO> getProgramsByMember(Long memberId, Pageable pageable) {
        return programRepository.findByMemberId(memberId, pageable).map(mapper::toTrainingProgramDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<TrainingProgramDTO> getProgramsByCoach(Long coachId, Pageable pageable) {
        return programRepository.findByCoachId(coachId, pageable).map(mapper::toTrainingProgramDTO);
    }

    @Override
    public TrainingProgramDTO updateProgram(Long id, TrainingProgramDTO dto) {
        log.info("Updating program: {}", id);
        TrainingProgram program = programRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Program not found with id: " + id));

        if (dto.getName() != null)        program.setName(dto.getName());
        if (dto.getDescription() != null) program.setDescription(dto.getDescription());
        if (dto.getStartDate() != null)   program.setStartDate(dto.getStartDate());
        if (dto.getEndDate() != null)     program.setEndDate(dto.getEndDate());
        if (dto.getStatus() != null)      program.setStatus(dto.getStatus());

        return mapper.toTrainingProgramDTO(programRepository.save(program));
    }

    @Override
    public void deleteProgram(Long id) {
        if (!programRepository.existsById(id)) {
            throw new EntityNotFoundException("Program not found with id: " + id);
        }
        programRepository.deleteById(id);
    }

    // ── Exercises ──────────────────────────────────────────────────────────────

    @Override
    public ExerciseDTO createExercise(ExerciseDTO dto) {
        log.info("Creating exercise: {}", dto.getName());
        Exercise exercise = Exercise.builder()
                .name(dto.getName())
                .description(dto.getDescription())
                .muscleGroup(dto.getMuscleGroup())
                .difficultyLevel(dto.getDifficultyLevel())
                .machineId(dto.getMachineId())
                .imageUrl(dto.getImageUrl())
                .build();

        return mapper.toExerciseDTO(exerciseRepository.save(exercise));
    }

    @Override
    @Transactional(readOnly = true)
    public ExerciseDTO getExerciseById(Long id) {
        return mapper.toExerciseDTO(exerciseRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Exercise not found with id: " + id)));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ExerciseDTO> getAllExercises(Pageable pageable) {
        return exerciseRepository.findAll(pageable).map(mapper::toExerciseDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ExerciseDTO> getExercisesByMuscleGroup(String muscleGroup, Pageable pageable) {
        return exerciseRepository.findByMuscleGroup(muscleGroup, pageable).map(mapper::toExerciseDTO);
    }

    @Override
    public ExerciseDTO updateExercise(Long id, ExerciseDTO dto) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Exercise not found with id: " + id));

        if (dto.getName() != null)            exercise.setName(dto.getName());
        if (dto.getDescription() != null)     exercise.setDescription(dto.getDescription());
        if (dto.getMuscleGroup() != null)     exercise.setMuscleGroup(dto.getMuscleGroup());
        if (dto.getDifficultyLevel() != null) exercise.setDifficultyLevel(dto.getDifficultyLevel());
        if (dto.getMachineId() != null)       exercise.setMachineId(dto.getMachineId());
        if (dto.getImageUrl() != null)        exercise.setImageUrl(dto.getImageUrl());

        return mapper.toExerciseDTO(exerciseRepository.save(exercise));
    }

    @Override
    public void deleteExercise(Long id) {
        if (!exerciseRepository.existsById(id))
            throw new EntityNotFoundException("Exercise not found");
        exerciseRepository.deleteById(id);
    }
}
