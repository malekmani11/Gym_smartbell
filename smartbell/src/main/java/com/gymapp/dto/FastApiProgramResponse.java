package com.gymapp.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FastApiProgramResponse {

    private List<SeanceAiDto> seances;

    @JsonProperty("note_coach")
    private String noteCoach;

    @JsonProperty("type_programme")
    private String typeProgramme;

    private int intensite;

    private String split;

    private double imc;

    @JsonProperty("imc_categorie")
    private String imcCategorie;
}
