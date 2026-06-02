package com.gymapp.dto;

import lombok.*;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SeanceAiDto {
    private String              nom;
    private List<ExerciceAiDto> exercices;
}
