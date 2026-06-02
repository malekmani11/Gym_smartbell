package com.gymapp.member.scheduler;

import com.gymapp.member.entity.Subscription;
import com.gymapp.member.entity.enums.SubscriptionStatus;
import com.gymapp.member.repository.SubscriptionRepository;
import com.gymapp.member.service.SubscriptionService;
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

    // ── Expire les abonnements terminés — tous les jours à minuit ─────────────
    @Scheduled(cron = "0 0 0 * * *")
    public void expireSubscriptions() {
        log.info("Scheduler — vérification des abonnements expirés");
        subscriptionService.checkAndExpireSubscriptions();
    }

    // ── Log des abonnements qui expirent dans 3 jours — tous les jours à 9h ──
    // (Les notifications sont envoyées par notification-service via son propre scheduler
    //  ou un event-driven mechanism)
    @Scheduled(cron = "0 0 9 * * *")
    public void logExpiryReminders() {
        LocalDate in3Days = LocalDate.now().plusDays(3);

        List<Subscription> expiringSoon = subscriptionRepository.findByStatusAndEndDateBetween(
                SubscriptionStatus.ACTIVE, LocalDate.now(), in3Days);

        expiringSoon.forEach(sub -> log.info(
                "Abonnement expirant bientôt — userId={} plan={} expiry={}",
                sub.getUser().getId(), sub.getPlan().getName(), sub.getEndDate()));

        log.info("Scheduler — {} abonnement(s) expirant dans 3 jours", expiringSoon.size());
    }
}
