package com.gymapp.service;

import com.gymapp.dto.TrainingProgramDTO;
import com.gymapp.dto.ExerciseDTO;
import com.gymapp.dto.MachineDTO;
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

    // Exercises
    ExerciseDTO createExercise(ExerciseDTO dto);

    ExerciseDTO getExerciseById(Long id);

    Page<ExerciseDTO> getAllExercises(Pageable pageable);

    Page<ExerciseDTO> getExercisesByMuscleGroup(String muscleGroup, Pageable pageable);

    ExerciseDTO updateExercise(Long id, ExerciseDTO dto);

    void deleteExercise(Long id);

    // Machines
    MachineDTO createMachine(MachineDTO dto);

    MachineDTO getMachineById(Long id);

    Page<MachineDTO> getAllMachines(Pageable pageable);

    MachineDTO updateMachine(Long id, MachineDTO dto);

    void deleteMachine(Long id);

    MachineDTO getMachineByQrData(String qrData);
}
