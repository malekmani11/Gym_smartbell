package com.gymapp.notification.controller;

import com.gymapp.notification.entity.DeviceToken;
import com.gymapp.notification.entity.User;
import com.gymapp.notification.repository.DeviceTokenRepository;
import com.gymapp.notification.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
public class DeviceTokenController {

    private final DeviceTokenRepository deviceTokenRepo;
    private final UserRepository userRepository;

    @PostMapping("/token")
    public ResponseEntity<Void> registerToken(
            @RequestBody Map<String, String> body,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        if (userId == null) {
            userId = extractUserIdFromToken(authHeader);
        }
        if (userId == null) return ResponseEntity.badRequest().build();

        String token    = body.get("token");
        String platform = body.getOrDefault("platform", "ANDROID");

        if (token == null || token.isBlank()) return ResponseEntity.badRequest().build();

        final Long finalUserId = userId;
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new EntityNotFoundException("User not found: " + finalUserId));

        deviceTokenRepo.findByUserIdAndToken(userId, token).orElseGet(() ->
            deviceTokenRepo.save(DeviceToken.builder()
                .user(user).token(token).platform(platform).build())
        );

        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/token")
    public ResponseEntity<Void> removeToken(
            @RequestBody Map<String, String> body,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        if (userId == null) userId = extractUserIdFromToken(authHeader);
        String token = body.get("token");
        if (userId != null && token != null) {
            deviceTokenRepo.deleteByUserIdAndToken(userId, token);
        }
        return ResponseEntity.noContent().build();
    }

    private Long extractUserIdFromToken(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) return null;
        try {
            String token = authHeader.substring(7);
            String[] parts = token.split("\\.");
            if (parts.length < 2) return null;
            String padded = parts[1] + "=".repeat((4 - parts[1].length() % 4) % 4);
            String json = new String(java.util.Base64.getUrlDecoder().decode(padded));
            // sub = email, pas userId — retourner null et laisser le controller échouer gracieusement
            return null;
        } catch (Exception e) {
            return null;
        }
    }
}
