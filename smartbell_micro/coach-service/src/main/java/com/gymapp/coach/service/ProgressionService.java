package com.gymapp.coach.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProgressionService {

    private final GroqService groqService;

    public String evaluerProgression(
            String prenom,
            String nom,
            String objectif,
            double poidsInitial,
            double poidsActuel,
            int seancesMois,
            int seancesObjectifMois,
            int moisDepuisInscription,
            String niveau) {

        double variationPoids  = poidsActuel - poidsInitial;
        double tauxAssiduite   = seancesObjectifMois > 0
                ? (double) seancesMois / seancesObjectifMois * 100.0
                : 0.0;

        String sensVariation = variationPoids > 0 ? "+" : "";

        log.info("Evaluating progression via Groq — membre={} {} objectif={} assiduite={}%",
                prenom, nom, objectif, String.format("%.1f", tauxAssiduite));

        String prompt = """
                Tu es un coach expert de SmartBell Gym, une salle de sport moderne en Tunisie.
                Évalue la progression de ce membre et fournis un rapport personnalisé en français.

                === PROFIL DU MEMBRE ===
                - Prénom                  : %s
                - Nom                     : %s
                - Niveau                  : %s
                - Objectif                : %s
                - Mois depuis inscription : %d mois

                === DONNÉES DE PROGRESSION ===
                - Poids initial           : %.1f kg
                - Poids actuel            : %.1f kg
                - Variation de poids      : %s%.1f kg
                - Séances effectuées      : %d / %d prévues ce mois
                - Taux d'assiduité        : %.1f %%

                === CONSIGNES ===
                - Le message_motivation doit commencer par le prénom "%s"
                - score_progression : entier entre 0 et 100, tenant compte de l'assiduité,
                  de la variation de poids par rapport à l'objectif, et du niveau
                - points_fidelite_suggeres : entier entre 50 et 200 selon la performance globale
                - badge_merite : nom court + 1 emoji représentatif (ex. "Guerrier du Cardio 🔥")
                - Ton : encourageant, jamais négatif, valorise les efforts même modestes

                Réponds UNIQUEMENT avec un objet JSON valide (sans texte avant ni après) :

                {
                  "score_progression": 0,
                  "score_justification": "...",
                  "message_motivation": "...",
                  "points_forts": ["...", "...", "..."],
                  "axes_amelioration": ["...", "..."],
                  "objectif_mois_prochain": "...",
                  "badge_merite": "...",
                  "points_fidelite_suggeres": 0
                }
                """.formatted(
                prenom, nom, niveau, objectif, moisDepuisInscription,
                poidsInitial, poidsActuel,
                sensVariation, Math.abs(variationPoids),
                seancesMois, seancesObjectifMois,
                tauxAssiduite,
                prenom);

        String result = groqService.call(prompt);
        log.debug("Progression evaluation received — membre={} {} score_length={}",
                prenom, nom, result != null ? result.length() : 0);
        return result;
    }
}
