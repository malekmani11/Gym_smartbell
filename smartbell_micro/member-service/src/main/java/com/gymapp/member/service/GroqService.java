package com.gymapp.member.service;

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

    @Value("${groq.api.key:}")
    private String apiKey;

    @Value("${groq.api.url:https://api.groq.com/openai/v1/chat/completions}")
    private String apiUrl;

    @Value("${groq.model:llama3-8b-8192}")
    private String model;

    private final WebClient webClient;

    public GroqService(WebClient webClient) {
        this.webClient = webClient;
    }

    public String call(String prompt) {
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("Groq API key not configured — returning placeholder");
            return "{\"error\":\"Groq API key not configured\"}";
        }

        var requestBody = Map.of(
            "model",       model,
            "max_tokens",  1024,
            "temperature", 0.7,
            "messages",    List.of(Map.of("role", "user", "content", prompt))
        );

        try {
            Map<?, ?> response = webClient.post()
                .uri(URI.create(apiUrl))
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .bodyValue((Object) requestBody)
                .retrieve()
                .bodyToMono(Map.class)
                .block();

            if (response == null) throw new RuntimeException("Groq API returned null response");

            var choices = (List<?>) response.get("choices");
            if (choices == null || choices.isEmpty()) throw new RuntimeException("Groq API response missing 'choices'");

            var message = (Map<?, ?>) ((Map<?, ?>) choices.get(0)).get("message");
            return (String) message.get("content");

        } catch (WebClientResponseException e) {
            log.error("Groq API HTTP error {} — {}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new RuntimeException("Groq API error: " + e.getStatusCode(), e);
        }
    }
}
