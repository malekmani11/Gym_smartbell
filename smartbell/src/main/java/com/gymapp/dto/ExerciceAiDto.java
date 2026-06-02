package com.gymapp.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExerciceAiDto {
    private int    id;
    private String name;
    private int    sets;
    private int    reps;
    private double weight;
    private int    restSeconds;
    private String muscles;
}
