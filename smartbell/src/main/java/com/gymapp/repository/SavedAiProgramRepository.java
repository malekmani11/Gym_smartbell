package com.gymapp.repository;

import com.gymapp.entity.SavedAiProgram;
import com.gymapp.entity.enums.AiProgramStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SavedAiProgramRepository extends JpaRepository<SavedAiProgram, Long> {

    List<SavedAiProgram> findByMemberId(Long memberId);

    List<SavedAiProgram> findByCoachIdAndStatus(Long coachId, AiProgramStatus status);

    List<SavedAiProgram> findByCoachId(Long coachId);
}
