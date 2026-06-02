package com.gymapp.coach.service;

import com.gymapp.coach.dto.AiProgramRequest;
import com.gymapp.coach.dto.AiProgramResponse;

public interface AiProgramService {

    AiProgramResponse generateProgram(Long memberId, AiProgramRequest request);
}
