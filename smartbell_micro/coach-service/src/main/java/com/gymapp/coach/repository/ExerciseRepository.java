package com.gymapp.coach.repository;

import com.gymapp.coach.entity.Exercise;
import com.gymapp.coach.entity.enums.DifficultyLevel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExerciseRepository extends JpaRepository<Exercise, Long> {

    Page<Exercise> findByMuscleGroup(String muscleGroup, Pageable pageable);

    List<Exercise> findByDifficultyLevel(DifficultyLevel level);

    List<Exercise> findByMachineId(Long machineId);
}
