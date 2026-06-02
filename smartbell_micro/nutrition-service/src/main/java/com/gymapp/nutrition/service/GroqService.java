package com.gymapp.nutrition.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.net.URI;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class GroqService {

    @Value("${groq.api.key}")
    private String apiKey;

    @Value("${groq.api.url}")
    private String apiUrl;

    @Value("${groq.model}")
    private String model;

    private final WebClient webClient;

    public GroqService(WebClient.Builder builder) {
        this.webClient = builder.build();
    }

    /**
     * Sends a prompt to the Groq API and returns the generated text.
     */
    public String call(String prompt) {
        var requestBody = Map.of(
            "model",       model,
            "max_tokens",  1024,
            "temperature", 0.7,
            "messages",    List.of(
                Map.of("role", "user", "content", prompt)
            )
        );

        log.debug("Calling Groq API — model={} prompt_length={}", model, prompt.length());

        try {
            Map<?, ?> response = webClient.post()
                .uri(URI.create(apiUrl))
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .bodyValue((Object) requestBody)
                .retrieve()
                .bodyToMono(Map.class)
                .block();

            if (response == null) {
                log.error("Groq API returned null response");
                throw new RuntimeException("Groq API returned null response");
            }

            var choices = (List<?>) response.get("choices");
            if (choices == null || choices.isEmpty()) {
                log.error("Groq API response missing 'choices': {}", response);
                throw new RuntimeException("Groq API response missing 'choices'");
            }

            var firstChoice = (Map<?, ?>) choices.get(0);
            var message     = (Map<?, ?>) firstChoice.get("message");
            if (message == null) {
                log.error("Groq API choice missing 'message': {}", firstChoice);
                throw new RuntimeException("Groq API choice missing 'message'");
            }

            String content = (String) message.get("content");
            log.debug("Groq API response received — length={}", content != null ? content.length() : 0);
            return content;

        } catch (WebClientResponseException e) {
            log.error("Groq API HTTP error {} — body: {}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new RuntimeException("Groq API error " + e.getStatusCode() + ": " + e.getResponseBodyAsString(), e);
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            log.error("Unexpected error calling Groq API: {}", e.getMessage(), e);
            throw new RuntimeException("Unexpected error calling Groq API: " + e.getMessage(), e);
        }
    }
}
