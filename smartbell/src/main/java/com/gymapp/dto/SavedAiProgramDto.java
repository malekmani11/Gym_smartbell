package com.gymapp.dto;

import com.gymapp.entity.enums.AiProgramStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SavedAiProgramDto {

    private Long id;
    private Long memberId;
    private String memberFirstName;
    private String memberLastName;
    private Long coachId;
    private AiProgramStatus status;
    private List<SeanceAiDto> seances;
    private String noteCoach;
    private String typeProgramme;
    private int intensite;
    private String split;
    private double imc;
    private String imcCategorie;
    private String coachComment;
    private LocalDateTime createdAt;
    private LocalDateTime validatedAt;
}
