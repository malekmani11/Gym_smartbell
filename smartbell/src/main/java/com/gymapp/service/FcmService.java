package com.gymapp.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.*;
import com.gymapp.entity.Role;
import com.gymapp.repository.DeviceTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class FcmService {

    private final DeviceTokenRepository deviceTokenRepo;

    // ── Envoyer à un user spécifique ─────────────────────────────────────────

    public void sendToUser(Long userId, String title, String body) {
        if (!isFirebaseAvailable()) return;
        List<String> tokens = deviceTokenRepo.findTokensByUserId(userId);
        send(tokens, title, body);
    }

    // ── Envoyer à tous les users d'un rôle ───────────────────────────────────

    public void sendToRole(Role role, String title, String body) {
        if (!isFirebaseAvailable()) return;
        List<String> tokens = deviceTokenRepo.findTokensByRole(role);
        send(tokens, title, body);
    }

    // ── Envoyer à tous les users ──────────────────────────────────────────────

    public void sendToAll(String title, String body) {
        if (!isFirebaseAvailable()) return;
        List<String> tokens = deviceTokenRepo.findAllTokens();
        send(tokens, title, body);
    }

    // ── Logique d'envoi ───────────────────────────────────────────────────────

    private void send(List<String> tokens, String title, String body) {
        if (tokens.isEmpty()) return;

        // FCM limite à 500 tokens par requête multicast
        int batchSize = 500;
        for (int i = 0; i < tokens.size(); i += batchSize) {
            List<String> batch = tokens.subList(i, Math.min(i + batchSize, tokens.size()));
            try {
                MulticastMessage message = MulticastMessage.builder()
                    .setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build())
                    .addAllTokens(batch)
                    .build();

                BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
                log.info("FCM envoyé: {} succès, {} échecs sur {} tokens",
                    response.getSuccessCount(), response.getFailureCount(), batch.size());
            } catch (FirebaseMessagingException e) {
                log.error("Erreur FCM: {}", e.getMessage());
            }
        }
    }

    private boolean isFirebaseAvailable() {
        return !FirebaseApp.getApps().isEmpty();
    }
}
