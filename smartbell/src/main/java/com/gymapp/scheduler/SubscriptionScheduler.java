package com.gymapp.scheduler;

import com.gymapp.dto.BroadcastNotificationRequest;
import com.gymapp.entity.Subscription;
import com.gymapp.entity.enums.NotificationType;
import com.gymapp.entity.enums.SubscriptionStatus;
import com.gymapp.repository.SubscriptionRepository;
import com.gymapp.service.NotificationService;
import com.gymapp.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class SubscriptionScheduler {

    private final SubscriptionService    subscriptionService;
    private final SubscriptionRepository subscriptionRepository;
    private final NotificationService    notificationService;

    // ── Expire les abonnements terminés — tous les jours à minuit ─────────────
    @Scheduled(cron = "0 0 0 * * *")
    public void expireSubscriptions() {
        log.info("Scheduler — vérification des abonnements expirés");
        subscriptionService.checkAndExpireSubscriptions();
    }

    // ── Rappel 3 jours avant expiration — tous les jours à 9h ────────────────
    @Scheduled(cron = "0 0 9 * * *")
    public void sendExpiryReminders() {
        LocalDate in3Days = LocalDate.now().plusDays(3);

        List<Subscription> expiringSoon = subscriptionRepository
                .findByStatusAndEndDateBetween(
                        SubscriptionStatus.ACTIVE,
                        LocalDate.now(),
                        in3Days
                );

        expiringSoon.forEach(sub -> {
            Long userId = sub.getUser().getId();
            String memberName = sub.getUser().getFirstName();

            BroadcastNotificationRequest req = new BroadcastNotificationRequest();
            req.setTitle("⏰ Abonnement bientôt expiré");
            req.setMessage("Bonjour " + memberName + ", votre abonnement \""
                    + sub.getPlan().getName() + "\" expire le "
                    + sub.getEndDate() + ". Renouvelez-le dès maintenant !");
            req.setType(NotificationType.REMINDER);
            req.setTargetAll(false);
            req.setUserId(userId);

            notificationService.broadcast(req);
            log.info("Rappel envoyé → userId={} expiry={}", userId, sub.getEndDate());
        });

        log.info("Scheduler — {} rappel(s) d'expiration envoyé(s)", expiringSoon.size());
    }
}
