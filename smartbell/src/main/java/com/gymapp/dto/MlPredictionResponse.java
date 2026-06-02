package com.gymapp.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MlPredictionResponse {

    @JsonProperty("type_programme")
    private String typeProgramme;

    private String intensite;

    @JsonProperty("split_musculaire")
    private String splitMusculaire;
}
