package com.gymapp.repository;

import com.gymapp.entity.TrainingProgram;
import com.gymapp.entity.enums.ProgramStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TrainingProgramRepository extends JpaRepository<TrainingProgram, Long> {

    Page<TrainingProgram> findByMemberId(Long memberId, Pageable pageable);

    Page<TrainingProgram> findByCoachId(Long coachId, Pageable pageable);

    List<TrainingProgram> findByMemberIdAndStatus(Long memberId, ProgramStatus status);

    List<TrainingProgram> findByCoachIdAndStatus(Long coachId, ProgramStatus status);
}
