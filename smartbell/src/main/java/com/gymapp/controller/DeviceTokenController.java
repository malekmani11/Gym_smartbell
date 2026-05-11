package com.gymapp.controller;

import com.gymapp.entity.DeviceToken;
import com.gymapp.entity.User;
import com.gymapp.repository.DeviceTokenRepository;
import com.gymapp.repository.UserRepository;
import com.gymapp.security.CustomUserDetails;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
public class DeviceTokenController {

    private final DeviceTokenRepository deviceTokenRepo;
    private final UserRepository userRepository;

    // POST /api/devices/token  { "token": "...", "platform": "ANDROID" }
    @PostMapping("/token")
    public ResponseEntity<Void> registerToken(
            @RequestBody Map<String, String> body,
            Authentication authentication) {

        Long userId = ((CustomUserDetails) authentication.getPrincipal()).getUser().getId();
        String token    = body.get("token");
        String platform = body.getOrDefault("platform", "ANDROID");

        if (token == null || token.isBlank()) {
            return ResponseEntity.badRequest().build();
        }

        User user = userRepository.findById(userId)
            .orElseThrow(() -> new EntityNotFoundException("User not found: " + userId));

        // Upsert — si le token existe déjà pour cet user, on ne crée pas de doublon
        deviceTokenRepo.findByUserIdAndToken(userId, token).orElseGet(() ->
            deviceTokenRepo.save(DeviceToken.builder()
                .user(user)
                .token(token)
                .platform(platform)
                .build())
        );

        return ResponseEntity.ok().build();
    }

    // DELETE /api/devices/token  { "token": "..." }
    @DeleteMapping("/token")
    public ResponseEntity<Void> removeToken(
            @RequestBody Map<String, String> body,
            Authentication authentication) {

        Long userId = ((CustomUserDetails) authentication.getPrincipal()).getUser().getId();
        String token = body.get("token");
        if (token != null) {
            deviceTokenRepo.deleteByUserIdAndToken(userId, token);
        }
        return ResponseEntity.noContent().build();
    }
}
