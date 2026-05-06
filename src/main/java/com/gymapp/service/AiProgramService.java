package com.gymapp.service;

import com.gymapp.dto.AiProgramRequest;
import com.gymapp.dto.AiProgramResponse;

public interface AiProgramService {

    AiProgramResponse generateProgram(Long memberId, AiProgramRequest request);
}
