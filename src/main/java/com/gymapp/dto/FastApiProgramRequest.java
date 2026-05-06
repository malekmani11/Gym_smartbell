package com.gymapp.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FastApiProgramRequest {

    private double poids;
    private double taille;
    private int    age;
    private String sexe;
    private String objectif;
    private String niveau;
    private int    seances;
}
