package com.gymapp.dto;

import com.gymapp.entity.enums.AiProgramStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ValidateProgramRequest {

    @NotNull
    private AiProgramStatus status; // APPROVED or REJECTED

    private String coachComment;
}
