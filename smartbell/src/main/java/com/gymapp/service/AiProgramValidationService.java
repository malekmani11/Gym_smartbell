package com.gymapp.service;

import com.gymapp.dto.SavedAiProgramDto;
import com.gymapp.dto.ValidateProgramRequest;
import com.gymapp.entity.enums.AiProgramStatus;

import java.util.List;

public interface AiProgramValidationService {

    List<SavedAiProgramDto> getProgramsByCoach(Long coachId, AiProgramStatus status);

    List<SavedAiProgramDto> getProgramsByMember(Long memberId);

    SavedAiProgramDto validateProgram(Long programId, Long coachId, ValidateProgramRequest request);
}
