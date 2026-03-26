package com.gymapp.repository;

import com.gymapp.entity.TrainingProgramExercise;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TrainingProgramExerciseRepository extends JpaRepository<TrainingProgramExercise, Long> {

    List<TrainingProgramExercise> findByTrainingProgramIdOrderByDayNumberAscOrderIndexAsc(Long programId);

    List<TrainingProgramExercise> findByTrainingProgramIdAndDayNumber(Long programId, Integer dayNumber);

    void deleteByTrainingProgramId(Long programId);
}
