package com.gymapp.coach.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FastApiProgramRequest {
    private Double poids;
    private Double taille;
    private Integer age;
    private String sexe;
    private String objectif;
    private String niveau;
    private int seances;
}
