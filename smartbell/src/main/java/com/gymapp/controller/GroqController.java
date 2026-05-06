package com.gymapp.controller;

import com.gymapp.service.DashboardAnalyseService;
import com.gymapp.service.NotificationAiService;
import com.gymapp.service.ProgressionService;
import com.gymapp.service.RapportMensuelService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
@Slf4j
public class GroqController {

    private final DashboardAnalyseService dashboardAnalyseService;
    private final NotificationAiService   notificationAiService;
    private final ProgressionService      progressionService;
    private final RapportMensuelService   rapportMensuelService;

    // ──────────────────────────────────────────────────────────────────────────
    //  1. Analyse dashboard
    // ──────────────────────────────────────────────────────────────────────────
    @PostMapping("/dashboard-analyse")
    public ResponseEntity<Map<String, String>> dashboardAnalyse(
            @RequestParam int    membresActifs,
            @RequestParam int    nouveauxMembres,
            @RequestParam int    membresInactifs,
            @RequestParam double revenuTotal,
            @RequestParam int    seancesEffectuees,
            @RequestParam int    reservationsCours,
            @RequestParam double tauxRetention) {

        log.info("POST /api/ai/dashboard-analyse — membresActifs={} revenu={}", membresActifs, revenuTotal);

        String result = dashboardAnalyseService.analyserDashboard(
                membresActifs, nouveauxMembres, membresInactifs,
                revenuTotal, seancesEffectuees, reservationsCours, tauxRetention);

        return ResponseEntity.ok(Map.of("result", result));
    }

    // ──────────────────────────────────────────────────────────────────────────
    //  2. Génération notification ciblée
    // ──────────────────────────────────────────────────────────────────────────
    @PostMapping("/notification-generate")
    public ResponseEntity<Map<String, String>> notificationGenerate(
            @RequestParam                      String typeNotification,
            @RequestParam                      String cible,
            @RequestParam                      String sujet,
            @RequestParam(defaultValue = "")   String contexte) {

        log.info("POST /api/ai/notification-generate — type={} cible={}", typeNotification, cible);

        String result = notificationAiService.genererNotification(
                typeNotification, cible, sujet, contexte);

        return ResponseEntity.ok(Map.of("result", result));
    }

    // ──────────────────────────────────────────────────────────────────────────
    //  3. Message de réactivation membre inactif
    // ──────────────────────────────────────────────────────────────────────────
    @PostMapping("/notification-reactivation")
    public ResponseEntity<Map<String, String>> notificationReactivation(
            @RequestParam String prenomMembre,
            @RequestParam int    joursAbsence,
            @RequestParam String dernierObjectif) {

        log.info("POST /api/ai/notification-reactivation — prenom={} absence={}j", prenomMembre, joursAbsence);

        String result = notificationAiService.genererMessageReactivation(
                prenomMembre, joursAbsence, dernierObjectif);

        return ResponseEntity.ok(Map.of("result", result));
    }

    // ──────────────────────────────────────────────────────────────────────────
    //  4. Évaluation progression membre
    // ──────────────────────────────────────────────────────────────────────────
    @PostMapping("/progression/{memberId}")
    public ResponseEntity<Map<String, String>> evaluerProgression(
            @PathVariable Long   memberId,
            @RequestParam String prenom,
            @RequestParam String nom,
            @RequestParam String objectif,
            @RequestParam double poidsInitial,
            @RequestParam double poidsActuel,
            @RequestParam int    seancesMois,
            @RequestParam int    seancesObjectifMois,
            @RequestParam int    moisDepuisInscription,
            @RequestParam String niveau) {

        log.info("POST /api/ai/progression/{} — membre={} {} objectif={}", memberId, prenom, nom, objectif);

        String result = progressionService.evaluerProgression(
                prenom, nom, objectif,
                poidsInitial, poidsActuel,
                seancesMois, seancesObjectifMois,
                moisDepuisInscription, niveau);

        return ResponseEntity.ok(Map.of("result", result));
    }

    // ──────────────────────────────────────────────────────────────────────────
    //  5. Rapport mensuel
    // ──────────────────────────────────────────────────────────────────────────
    @PostMapping("/rapport-mensuel")
    public ResponseEntity<Map<String, String>> rapportMensuel(
            @RequestParam String mois,
            @RequestParam int    annee,
            @RequestParam int    membresActifs,
            @RequestParam int    nouveauxMembres,
            @RequestParam int    membresPartis,
            @RequestParam double revenuAbonnements,
            @RequestParam double revenuCours,
            @RequestParam double revenuTotal,
            @RequestParam int    seancesTotal,
            @RequestParam String coursPlusPopulaire,
            @RequestParam String coachMieuxNote,
            @RequestParam int    tauxSatisfaction) {

        log.info("POST /api/ai/rapport-mensuel — periode={}/{} revenu={}DT", mois, annee, revenuTotal);

        String result = rapportMensuelService.genererRapport(
                mois, annee,
                membresActifs, nouveauxMembres, membresPartis,
                revenuAbonnements, revenuCours, revenuTotal,
                seancesTotal, coursPlusPopulaire, coachMieuxNote, tauxSatisfaction);

        return ResponseEntity.ok(Map.of("result", result));
    }
}
