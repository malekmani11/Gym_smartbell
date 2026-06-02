package com.gymapp.coach.service.impl;

import com.gymapp.coach.dto.AiProgramRequest;
import com.gymapp.coach.dto.AiProgramResponse;
import com.gymapp.coach.dto.FastApiProgramRequest;
import com.gymapp.coach.dto.FastApiProgramResponse;
import com.gymapp.coach.service.AiProgramService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientRequestException;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.Objects;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class AiProgramServiceImpl implements AiProgramService {

    private final WebClient webClient;

    @Value("${ml.api.url:http://localhost:8000}")
    private String mlApiBaseUrl;

    @Override
    public AiProgramResponse generateProgram(Long memberId, AiProgramRequest request) {
        Objects.requireNonNull(memberId, "memberId ne peut pas être null");
        log.info("Génération de programme ML pour le membre id={}", memberId);

        FastApiProgramResponse fastApiRes = callMlApi(
                FastApiProgramRequest.builder()
                        .poids   (request.getPoids())
                        .taille  (request.getTaille())
                        .age     (request.getAge())
                        .sexe    (request.getSexe())
                        .objectif(request.getObjectif())
                        .niveau  (request.getNiveau())
                        .seances (request.getSeances())
                        .build()
        );

        return AiProgramResponse.builder()
                .programme    (fastApiRes.getProgramme())
                .typeProgramme(fastApiRes.getTypeProgramme())
                .intensite    (fastApiRes.getIntensite())
                .split        (fastApiRes.getSplit())
                .imc          (fastApiRes.getImc())
                .imcCategorie (fastApiRes.getImcCategorie())
                .build();
    }

    // ── Appel FastAPI ─────────────────────────────────────────────────────────

    private FastApiProgramResponse callMlApi(FastApiProgramRequest request) {
        String url = mlApiBaseUrl + "/api/ai/generate-program";
        try {
            FastApiProgramResponse response = webClient.post()
                    .uri(url)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .retrieve()
                    .onStatus(
                            status -> status.is4xxClientError(),
                            resp -> resp.bodyToMono(String.class).map(body ->
                                    new IllegalStateException("Erreur client ML (" + resp.statusCode() + ") : " + body))
                    )
                    .onStatus(
                            status -> status.is5xxServerError(),
                            resp -> resp.bodyToMono(String.class).map(body ->
                                    new IllegalStateException("Erreur serveur ML (" + resp.statusCode() + ") : " + body))
                    )
                    .bodyToMono(FastApiProgramResponse.class)
                    .block();

            if (response == null) {
                throw new IllegalStateException("Réponse vide du service ML");
            }
            log.info("Programme généré — type={} intensité={}/5 split={}",
                    response.getTypeProgramme(), response.getIntensite(), response.getSplit());
            return response;

        } catch (WebClientRequestException e) {
            log.error("Service ML indisponible à {}", url, e);
            throw new IllegalStateException(
                    "Le service ML est indisponible. Vérifiez que l'API FastAPI tourne sur " + mlApiBaseUrl, e);

        } catch (WebClientResponseException e) {
            log.error("Erreur HTTP {} du service ML : {}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new IllegalStateException(
                    "Erreur du service ML (" + e.getStatusCode() + ") : " + e.getResponseBodyAsString(), e);
        }
    }
}
