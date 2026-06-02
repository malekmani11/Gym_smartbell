package com.gymapp.coach.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FastApiProgramResponse {
    private String programme;

    @JsonProperty("type_programme")
    private String typeProgramme;

    private int intensite;
    private String split;
    private double imc;

    @JsonProperty("imc_categorie")
    private String imcCategorie;
}
