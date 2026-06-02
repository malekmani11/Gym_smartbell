package com.gymapp.coach.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiProgramRequest {

    @NotNull(message = "Le poids est obligatoire")
    @DecimalMin(value = "20.0", message = "Poids minimum : 20 kg")
    @DecimalMax(value = "300.0", message = "Poids maximum : 300 kg")
    private Double poids;

    @NotNull(message = "La taille est obligatoire")
    @DecimalMin(value = "100.0", message = "Taille minimum : 100 cm")
    @DecimalMax(value = "250.0", message = "Taille maximum : 250 cm")
    private Double taille;

    @NotNull(message = "L'âge est obligatoire")
    @Min(value = 10, message = "Âge minimum : 10 ans")
    @Max(value = 100, message = "Âge maximum : 100 ans")
    private Integer age;

    @NotBlank(message = "Le sexe est obligatoire")
    @Pattern(
        regexp = "homme|femme",
        message = "sexe doit être : homme ou femme"
    )
    private String sexe;

    @NotBlank(message = "L'objectif est obligatoire")
    @Pattern(
        regexp = "perte_poids|prise_masse|endurance|tonification",
        message = "objectif doit être : perte_poids, prise_masse, endurance ou tonification"
    )
    private String objectif;

    @NotBlank(message = "Le niveau est obligatoire")
    @Pattern(
        regexp = "debutant|intermediaire|avance",
        message = "niveau doit être : debutant, intermediaire ou avance"
    )
    private String niveau;

    @Min(value = 1, message = "Minimum 1 séance par semaine")
    @Max(value = 7, message = "Maximum 7 séances par semaine")
    @Builder.Default
    private int seances = 4;
}
