package com.gymapp.member.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class DashboardAnalyseService {

    private final GroqService groqService;

    public String analyserDashboard(
            int membresActifs,
            int nouveauxMembres,
            int membresInactifs,
            double revenuTotal,
            int seancesEffectuees,
            int reservationsCours,
            double tauxRetention) {

        String prompt = """
                Tu es un consultant business expert en gestion de salles de sport en Tunisie.
                Analyse les statistiques mensuelles de SmartBell Gym et fournis un rapport structuré.

                === DONNÉES DU MOIS ===
                - Membres actifs       : %d
                - Nouveaux membres     : %d
                - Membres inactifs     : %d
                - Revenu total         : %.2f DT
                - Séances effectuées   : %d
                - Réservations cours   : %d
                - Taux de rétention    : %.1f %%

                === CONSIGNES ===
                Réponds UNIQUEMENT avec un objet JSON valide respectant exactement cette structure
                (sans texte avant ni après) :

                {
                  "resume_executif": "...",
                  "points_positifs": ["...", "...", "..."],
                  "points_a_ameliorer": ["...", "...", "..."],
                  "recommandations": [
                    { "priorite": "haute",   "action": "...", "impact_estime": "..." },
                    { "priorite": "moyenne", "action": "...", "impact_estime": "..." },
                    { "priorite": "basse",   "action": "...", "impact_estime": "..." }
                  ],
                  "objectifs_mois_prochain": {
                    "membres_actifs_cible": 0,
                    "revenu_cible_dt": 0,
                    "taux_retention_cible_pct": 0,
                    "commentaire": "..."
                  }
                }
                """.formatted(
                membresActifs, nouveauxMembres, membresInactifs,
                revenuTotal, seancesEffectuees, reservationsCours, tauxRetention);

        log.info("Requesting dashboard analysis from Groq — membres_actifs={} revenu={} DT",
                membresActifs, revenuTotal);

        String result = groqService.call(prompt);

        log.debug("Dashboard analysis received — length={}", result != null ? result.length() : 0);
        return result;
    }
}
