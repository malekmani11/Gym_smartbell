package com.gymapp.notification.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationAiService {

    private final GroqService groqService;

    // ──────────────────────────────────────────────────────────────────────────
    //  1. Génération d'une notification ciblée (promo, rappel, motivation…)
    // ──────────────────────────────────────────────────────────────────────────
    public String genererNotification(
            String typeNotification,
            String cible,
            String sujet,
            String contexte) {

        String prompt = """
                Tu es un expert en communication marketing pour SmartBell Gym, une salle de sport moderne en Tunisie.
                Rédige une notification push/SMS professionnelle et engageante en français.

                === PARAMÈTRES ===
                - Type          : %s  (promo | rappel | motivation | événement | alerte)
                - Cible         : %s  (tous | membres_inactifs | abonnements_expirant | nouveaux | vip)
                - Sujet         : %s
                - Contexte supp.: %s

                === CONSIGNES RÉDACTIONNELLES ===
                - Ton : chaleureux, motivant, professionnel
                - Le message_sms ne doit PAS dépasser 80 caractères
                - Utilise un emoji pertinent dans le titre
                - Le call_to_action doit être un verbe d'action court (ex. "Réserver", "Profiter", "Revenir")
                - heure_envoi_conseillee : plage horaire optimale pour ce type de message (ex. "18h-20h")

                Réponds UNIQUEMENT avec un objet JSON valide (sans texte avant ni après) :

                {
                  "titre": "...",
                  "message_sms": "...(max 80 caractères)",
                  "message_app": "...",
                  "call_to_action": "...",
                  "heure_envoi_conseillee": "...",
                  "emoji": "..."
                }
                """.formatted(typeNotification, cible, sujet, contexte);

        log.info("Generating notification via Groq — type={} cible={}", typeNotification, cible);

        String result = groqService.call(prompt);
        log.debug("Notification generated — length={}", result != null ? result.length() : 0);
        return result;
    }

    // ──────────────────────────────────────────────────────────────────────────
    //  2. Message de réactivation personnalisé pour un membre inactif
    // ──────────────────────────────────────────────────────────────────────────
    public String genererMessageReactivation(
            String prenomMembre,
            int joursAbsence,
            String dernierObjectif) {

        String prompt = """
                Tu es le coach attitré de SmartBell Gym en Tunisie.
                Écris un message de réactivation chaleureux et motivant en français
                pour un membre qui ne s'est pas présenté depuis un moment.

                === PROFIL DU MEMBRE ===
                - Prénom          : %s
                - Absence         : %d jours
                - Dernier objectif: %s

                === CONSIGNES IMPÉRATIVES ===
                - Commence par interpeller le membre par son prénom
                - Rappelle son objectif "%s" de façon encourageante (sans culpabiliser)
                - Mentionne que SmartBell Gym l'attend et que son programme est prêt
                - Propose une action concrète pour revenir (ex. séance d'essai gratuite, RDV avec un coach)
                - Le message_court ne doit PAS dépasser 80 caractères
                - Ton : chaleureux, bienveillant, jamais culpabilisant

                Réponds UNIQUEMENT avec un objet JSON valide (sans texte avant ni après) :

                {
                  "message_court": "...(max 80 caractères)",
                  "message_complet": "...",
                  "objet_notification": "...",
                  "call_to_action": "...",
                  "emoji": "..."
                }
                """.formatted(prenomMembre, joursAbsence, dernierObjectif, dernierObjectif);

        log.info("Generating reactivation message via Groq — prenom={} absence={}j objectif={}",
                prenomMembre, joursAbsence, dernierObjectif);

        String result = groqService.call(prompt);
        log.debug("Reactivation message generated — length={}", result != null ? result.length() : 0);
        return result;
    }
}
