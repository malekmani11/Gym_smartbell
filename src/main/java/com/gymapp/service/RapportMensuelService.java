package com.gymapp.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class RapportMensuelService {

    private final GroqService groqService;

    public String genererRapport(
            String mois,
            int annee,
            int membresActifs,
            int nouveauxMembres,
            int membresPartis,
            double revenuAbonnements,
            double revenuCours,
            double revenuTotal,
            int seancesTotal,
            String coursPlusPopulaire,
            String coachMieuxNote,
            int tauxSatisfaction) {

        int croissanceNette = nouveauxMembres - membresPartis;
        String tendanceCroissance = croissanceNette >= 0
                ? "+" + croissanceNette + " (croissance)"
                : croissanceNette + " (décroissance)";

        double partRevenuAbonnements = revenuTotal > 0
                ? revenuAbonnements / revenuTotal * 100.0 : 0.0;
        double partRevenuCours = revenuTotal > 0
                ? revenuCours / revenuTotal * 100.0 : 0.0;

        log.info("Generating monthly report via Groq — periode={}/{} membres={} revenu={}DT",
                mois, annee, membresActifs, String.format("%.2f", revenuTotal));

        String prompt = """
                Tu es un consultant business senior spécialisé dans la gestion de salles de sport en Tunisie.
                Génère un rapport mensuel professionnel et structuré pour SmartBell Gym.

                === DONNÉES DU MOIS DE %s %d ===

                >> MEMBRES
                - Membres actifs total   : %d
                - Nouveaux inscrits      : %d
                - Membres ayant quitté   : %d
                - Croissance nette       : %s

                >> FINANCES
                - Revenu abonnements     : %.2f DT  (%.1f %% du total)
                - Revenu cours collectifs: %.2f DT  (%.1f %% du total)
                - Revenu total           : %.2f DT

                >> OPÉRATIONS
                - Séances effectuées     : %d
                - Cours le plus populaire: %s
                - Coach le mieux noté    : %s
                - Taux de satisfaction   : %d %%

                === CONSIGNES DE RÉDACTION ===
                - Style : professionnel, synthétique, orienté décision
                - Chaque section doit avoir un titre explicite en majuscules
                - Les recommandations stratégiques doivent être CHIFFRÉES (ex. "Objectif +15 nouveaux membres")
                - Ton : factuel pour l'analyse, positif et motivant pour la conclusion
                - Langue : français

                Réponds UNIQUEMENT avec un objet JSON valide (sans texte avant ni après) :

                {
                  "titre_rapport": "Rapport Mensuel SmartBell Gym — %s %d",
                  "resume_executif": "...",
                  "analyse_membres": {
                    "synthese": "...",
                    "points_cles": ["...", "...", "..."]
                  },
                  "analyse_financiere": {
                    "synthese": "...",
                    "points_cles": ["...", "...", "..."]
                  },
                  "performance_operationnelle": {
                    "synthese": "...",
                    "points_cles": ["...", "...", "..."]
                  },
                  "points_forts": ["...", "...", "..."],
                  "defis": ["...", "..."],
                  "recommandations_strategiques": [
                    { "priorite": "haute",   "action": "...", "objectif_chiffre": "...", "delai": "..." },
                    { "priorite": "moyenne", "action": "...", "objectif_chiffre": "...", "delai": "..." },
                    { "priorite": "basse",   "action": "...", "objectif_chiffre": "...", "delai": "..." }
                  ],
                  "objectifs_mois_prochain": {
                    "membres_actifs_cible": 0,
                    "nouveaux_membres_cible": 0,
                    "revenu_cible_dt": 0,
                    "taux_satisfaction_cible_pct": 0,
                    "commentaire": "..."
                  },
                  "conclusion": "..."
                }
                """.formatted(
                mois.toUpperCase(), annee,
                membresActifs,
                nouveauxMembres,
                membresPartis,
                tendanceCroissance,
                revenuAbonnements, partRevenuAbonnements,
                revenuCours, partRevenuCours,
                revenuTotal,
                seancesTotal,
                coursPlusPopulaire,
                coachMieuxNote,
                tauxSatisfaction,
                mois, annee);

        String result = groqService.call(prompt);
        log.debug("Monthly report generated — periode={}/{} length={}",
                mois, annee, result != null ? result.length() : 0);
        return result;
    }
}
